require 'resolv'

#
# Prometheus installation
# 

base_package_filename = File.basename(node['prometheus']['url'])
cached_package_filename = "#{Chef::Config['file_cache_path']}/#{base_package_filename}"

remote_file cached_package_filename do
  source node['prometheus']['url']
  owner "root"
  mode "0644"
  action :create_if_missing
end

directory node['prometheus']['root_dir'] do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode '0750'
  action :create
end

prometheus_downloaded= "#{node['prometheus']['home']}/.prometheus.extracted_#{node['prometheus']['version']}"
# Extract prometheus 
bash 'extract_prometheus' do
  user "root"
  code <<-EOH
    tar -xf #{cached_package_filename} -C #{node['prometheus']['root_dir']}
    chown -R #{node['hopsmonitor']['user']}:#{node['hopsmonitor']['group']} #{node['prometheus']['home']}
    chmod -R 750 #{node['prometheus']['home']}
    touch #{prometheus_downloaded}
    chown #{node['hopsmonitor']['user']} #{prometheus_downloaded}
  EOH
  not_if { ::File.exists?( prometheus_downloaded ) }
end

link node['prometheus']['base_dir'] do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  to node['prometheus']['home']
end

begin
  alertmanagers = private_recipe_ips("hopsmonitor", "alertmanager")
  alertmanagers = alertmanagers.map{ |alertmanager| 
    Resolv.getname(alertmanager) + ":" + node['alertmanager']['port'] 
  }
rescue 
  alertmanagers = []
end

begin
  node_exporters = private_recipe_ips("hopsmonitor", "node_exporter")
  node_exporters = node_exporters.map{ |node_exporter| 
    Resolv.getname(node_exporter) + ":" + node['node_exporter']['port'] 
  }
rescue
  node_exporters = []
end

begin
  mysqld_exporters = private_recipe_ips("ndb", "mysqld")
  mysqld_exporters = mysqld_exporters.map{ |mysqld_exporter| 
    Resolv.getname(mysqld_exporter) + ":" + node['ndb']['mysqld']['metrics_port']
  }
rescue
  mysqld_exporters = []
end

begin
  hops_exporters = []
  ['nn', 'dn', 'rm', 'nm'].each do |service| 
      hops_exporters << private_recipe_ips("hops", service).map{ |exporter| 
          Resolv.getname(exporter) + ":" + node['hops'][service]['metrics_port']
      }
  end
rescue
  hops_exporters = []
end

begin
  kafka_exporters = private_recipe_ips("kkafka", "default")
  kafka_exporters = kafka_exporters.map{ |kafka_exporter| 
    Resolv.getname(kafka_exporter) + ":" + node['kkafka']['metrics_port'] 
  }
rescue
  kafka_exporters = []
end

begin
  elastic_exporters = private_recipe_ips("elastic", "default")
  elastic_exporters = elastic_exporters.map{ |elastic_exporter| 
    Resolv.getname(elastic_exporter) + ":" + node['elastic']['exporter']['port']
  }
rescue
  elastic_exporters = []
end

begin
  hive_exporters_tmp = private_recipe_ips("hive2", "default")
  # This is a bit of a wild assumption. "hive2::default" actually call 
  # both server2 and metastore recipes. This means it deploys 2 services.
  # As such, we duplicate the elements in the array. This ofc is going to break
  # if we start using the specific recipes (server2.rb and metastore.rb) instead of 
  # the default.rb. The proper fix is to use a service discovery. 
  hive_exporters_tmp = hive_exporters_tmp * 2 
  hive_exporters = []
  i = 0
  while i < hive_exporters_tmp.length
    hive_exporters << Resolv.getname(hive_exporters_tmp[i]) + ":" + node['hive2']['hs2']['metrics_port'] 
    hive_exporters << Resolv.getname(hive_exporters_tmp[i+1]) + ":" + node['hive2']['hm']['metrics_port'] 
    i += 2
  end
rescue 
  hive_exporters = []
end

begin 
  airflow_exporters = private_recipe_ips("hops_airflow", "default")
  airflow_exporters = airflow_exporters.map{ |airflow_exporter| 
    Resolv.getname(airflow_exporter) + ":" + node['airflow']["config"]["webserver"]["web_server_port"].to_s
  }
rescue 
  airflow_exporters = []
end

begin
  hopsworks_port = "8181"
  if node.attribute?("hopsworks") && node['hopsworks'].attribute?("https") && node['hopsworks']['https'].attribute?("port")
    hopsworks_port = node['hopsworks']['https']['port'].to_s
  end
  hopsworks_exporters = private_recipe_ips("hopsworks", "default")
  hopsworks_exporters = hopsworks_exporters.map{ |hopsworks_exporter| 
    Resolv.getname(hopsworks_exporter) + ":" + hopsworks_port
  }
rescue
  hopsworks_exporters = []
end

begin
  epipe_exporters = private_recipe_ips("epipe", "default")
  epipe_exporters = epipe_exporters.map{ |epipe_exporter| 
    Resolv.getname(epipe_exporter) + ":" + node['epipe']["metrics_port"].to_s
  }
rescue
  epipe_exporters = []
end

template "#{node['prometheus']['base_dir']}/prometheus.yml" do
  source "prometheus.yml.erb" 
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode '0700'
  action :create
  variables({
      'alertmanagers' => alertmanagers.join("', '"),
      'node_exporters' => node_exporters.join("', '"),
      'mysqld_exporters' => mysqld_exporters.join("', '"),
      'hops_exporters' => hops_exporters.join("', '"),
      'kafka_exporters' => kafka_exporters.join("', '"),
      'elastic_exporters' => elastic_exporters.join("', '"),
      'hive_exporters' => hive_exporters.join("', '"),
      'airflow_exporters' => airflow_exporters.join("', '"),
      'hopsworks_exporters' => hopsworks_exporters.join("', '"),
      'epipe_exporters' => epipe_exporters.join("', '")
  })
end

directory node['prometheus']['rules_dir'] do 
  action :delete
  recursive true 
end

remote_directory node['prometheus']['rules_dir'] do 
  source "rules"
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode 0700
  files_owner node['hopsmonitor']['user']
  files_group node['hopsmonitor']['group']
  files_mode 0700
end

case node['platform_family']
when "rhel"
  systemd_script = "/usr/lib/systemd/system/prometheus.service" 
else
  systemd_script = "/lib/systemd/system/prometheus.service"
end

service "prometheus" do
  provider Chef::Provider::Service::Systemd
  supports :restart => true, :stop => true, :start => true, :status => true
  action :nothing
end

template systemd_script do
  source "prometheus.service.erb"
  owner "root"
  group "root"
  mode 0664
  if node['services']['enabled'] == "true"
    notifies :enable, "service[prometheus]"
  end
  notifies :restart, "service[prometheus]"
end

kagent_config "prometheus" do
  action :systemd_reload
end

if node['kagent']['enabled'] == "true"
   kagent_config "prometheus" do
     service "Monitoring"
     restart_agent false 
   end
end