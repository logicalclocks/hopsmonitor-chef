#
# Pushgateway installation
# 

base_package_filename = File.basename(node['pushgateway']['url'])
cached_package_filename = "#{Chef::Config['file_cache_path']}/#{base_package_filename}"

remote_file cached_package_filename do
  source node['pushgateway']['url']
  owner "root"
  mode "0644"
  action :create_if_missing
end

directory node['pushgateway']['root_dir'] do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode '0750'
  action :create
end

pushgateway_downloaded= "#{node['pushgateway']['home']}/.pushgateway.extracted_#{node['pushgateway']['version']}"
# Extract pushgateway 
bash 'extract_pushgateway' do
  user "root"
  code <<-EOH
    tar -xf #{cached_package_filename} -C #{node['pushgateway']['root_dir']}
    chown -R #{node['hopsmonitor']['user']}:#{node['hopsmonitor']['group']} #{node['pushgateway']['home']}
    chmod -R 750 #{node['pushgateway']['home']}
    touch #{pushgateway_downloaded}
    chown #{node['hopsmonitor']['user']} #{pushgateway_downloaded}
  EOH
  not_if { ::File.exists?( pushgateway_downloaded ) }
end

link node['pushgateway']['base_dir'] do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  to node['pushgateway']['home']
end

case node['platform_family']
when "rhel"
  systemd_script = "/usr/lib/systemd/system/pushgateway.service" 
else
  systemd_script = "/lib/systemd/system/pushgateway.service"
end

service "pushgateway" do
  provider Chef::Provider::Service::Systemd
  supports :restart => true, :stop => true, :start => true, :status => true
  action :nothing
end

template systemd_script do
  source "pushgateway.service.erb"
  owner "root"
  group "root"
  mode 0664
  if node['services']['enabled'] == "true"
    notifies :enable, "service[pushgateway]"
  end
  notifies :restart, "service[pushgateway]"
end

kagent_config "pushgateway" do
  action :systemd_reload
end

if node['kagent']['enabled'] == "true"
   kagent_config "pushgateway" do
     service "Monitoring"
     restart_agent false 
   end
end

if service_discovery_enabled()
  # Register Pushgateway with Consul
  consul_service "Registering Pushgateway with Consul" do
    service_definition "pushgateway-consul.hcl.erb"
    action :register
  end
end 