case node['platform']
when "ubuntu"
 if node['platform_version'].to_f <= 14.04
   node.override['kapacitor']['systemd'] = "false"
 end
end


#
# Kapacitor installation
#


package_url = "#{node['kapacitor']['url']}"
base_package_filename = File.basename(package_url)
cached_package_filename = "#{Chef::Config['file_cache_path']}/#{base_package_filename}"

remote_file cached_package_filename do
  source package_url
  owner "root"
  mode "0644"
  action :create_if_missing
end

package "logrotate"

kapacitor_downloaded = "#{node['kapacitor']['home']}/.kapacitor.extracted_#{node['kapacitor']['version']}"
# Extract kapacitor
bash 'extract_kapacitor' do
        user "root"
        code <<-EOH
                tar -xf #{cached_package_filename} -C #{node['hopsmonitor']['dir']}
                cd #{node['kapacitor']['home']}
                mkdir conf
                mkdir log
                cp etc/logrotate.d/kapacitor /etc/logrotate.d/kapacitor
                mv usr/bin bin/
                mv usr/lib/* /usr/lib
                rm -rf usr
                rm -rf etc
                rm -rf var
                chown -R #{node['hopsmonitor']['user']}:#{node['hopsmonitor']['group']} #{node['kapacitor']['home']}
                chmod 750 #{node['kapacitor']['home']}
                touch #{kapacitor_downloaded}
                chown #{node['hopsmonitor']['user']} #{kapacitor_downloaded}
        EOH
     not_if { ::File.exists?( kapacitor_downloaded ) }
end

link node['kapacitor']['base_dir'] do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  to node['kapacitor']['home']
end

template "/etc/logrotate.d/kapacitor" do
  source "logrotate.kapacitor.erb"
  owner "root"
  group "root"
  mode 0655
end

my_ip = my_private_ip()
influx_ip = private_recipe_ip("hopsmonitor","default")

# Query any local zookeeper broker
found_zk = ""
for zk in node['kzookeeper']['default']['private_ips']
  if my_ip.eql? zk
    Chef::Log.info "Telegraf found matching zk IP address"
    found_zk = zk
  end
end 

# Query any local elasticsearch broker
found_es = ""
for es in node['elastic']['default']['private_ips']
  if my_ip.eql? es
    Chef::Log.info "Telegraf found matching es IP address"
    found_es = es
  end
end 

# Query any local kafka broker
found_kafka = ""
for kafka in node['kkafka']['default']['private_ips']
  if my_ip.eql? kafka
    Chef::Log.info "Telegraf found matching kafka IP address"
    found_kafka = kafka
  end
end 


# Only query mysql from 1 telegraf agent. Pick the first mysql server.
found_mysql = ""
mysql = node['ndb']['mysqld']['private_ips'][0]
if my_ip.eql? mysql
  Chef::Log.info "Telegraf found matching mysql IP address"
  found_mysql = mysql
end 


template "#{node['kapacitor']['base_dir']}/conf/kapacitor.conf" do
  source "kapacitor.conf.erb"
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode 0750
  variables({ 
   :influx_ip => influx_ip,
   :zk_ip => found_zk,
   :elastic_ip => found_es,
   :kafka_ip => found_kafka,
   :mysql_ip => found_mysql,   
  })
end


directory "#{node['kapacitor']['base_dir']}/replay" do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode "750"
  action :create
end

directory "#{node['kapacitor']['base_dir']}/log" do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode "750"
  action :create
end

directory "#{node['kapacitor']['base_dir']}/tasks" do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode "750"
  action :create
end



service_name="kapacitor"

if node['kapacitor']['systemd'] == "true"

  service service_name do
    provider Chef::Provider::Service::Systemd
    supports :restart => true, :stop => true, :start => true, :status => true
    action :nothing
  end

  case node['platform_family']
  when "rhel"
    systemd_script = "/usr/lib/systemd/system/#{service_name}.service" 
  when "debian"
    systemd_script = "/lib/systemd/system/#{service_name}.service"
  end

  template systemd_script do
    source "#{service_name}.service.erb"
    owner "root"
    group "root"
    mode 0754
    notifies :enable, resources(:service => service_name)
    notifies :restart, resources(:service => service_name)
  end

  kagent_config "#{service_name}" do
    action :systemd_reload
  end  

else #sysv

  service service_name do
    provider Chef::Provider::Service::Init::Debian
    supports :restart => true, :stop => true, :start => true, :status => true
    action :nothing
  end

  template "/etc/init.d/#{service_name}" do
    source "#{service_name}.erb"
    owner node['hopsmonitor']['user']
    group node['hopsmonitor']['group']
    mode 0754
    notifies :enable, resources(:service => service_name)
    notifies :restart, resources(:service => service_name), :immediately
  end

end

if node['kagent']['enabled'] == "true" 
   kagent_config "kapacitor" do
     service "Monitoring"
     log_file "#{node['kapacitor']['base_dir']}/log/kapacitor.log"
   end
end


