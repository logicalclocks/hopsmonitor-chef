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
  mysqld_exporters = private_recipe_ips("ndb", "mysqld")
  mysqld_exporters = mysqld_exporters.map{ |mysqld_exporter| 
    Resolv.getname(mysqld_exporter) + ":" + node['ndb']['mysqld']['metrics_port']
  }
rescue
  mysqld_exporters = []
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

template "#{node['prometheus']['base_dir']}/prometheus.yml" do
  source "prometheus.yml.erb" 
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode '0700'
  action :create
  variables({
      'alertmanagers' => alertmanagers.join("', '"),
      'mysqld_exporters' => mysqld_exporters.join("', '"),
      'kafka_exporters' => kafka_exporters.join("', '"),
      'elastic_exporters' => elastic_exporters.join("', '"),
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