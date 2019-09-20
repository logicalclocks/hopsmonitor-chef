#
# Node exporter installation
# 

base_package_filename = File.basename(node['node_exporter']['url'])
cached_package_filename = "#{Chef::Config['file_cache_path']}/#{base_package_filename}"

remote_file cached_package_filename do
  source node['node_exporter']['url']
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

node_exporter_downloaded= "#{node['node_exporter']['home']}/.node_exporter.extracted_#{node['node_exporter']['version']}"
# Extract node_exporter 
bash 'extract_node_exporter' do
  user "root"
  code <<-EOH
    tar -xf #{cached_package_filename} -C #{node['prometheus']['root_dir']}
    chown -R #{node['hopsmonitor']['user']}:#{node['hopsmonitor']['group']} #{node['node_exporter']['home']}
    chmod -R 750 #{node['prometheus']['home']}
    touch #{node_exporter_downloaded}
    chown #{node['hopsmonitor']['user']} #{node_exporter_downloaded}
  EOH
  not_if { ::File.exists?( node_exporter_downloaded ) }
end

link node['node_exporter']['base_dir'] do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  to node['node_exporter']['home']
end

case node['platform_family']
when "rhel"
  systemd_script = "/usr/lib/systemd/system/node_exporter.service" 
else
  systemd_script = "/lib/systemd/system/node_exporter.service"
end

service "node_exporter" do
  provider Chef::Provider::Service::Systemd
  supports :restart => true, :stop => true, :start => true, :status => true
  action :nothing
end

template systemd_script do
  source "node_exporter.service.erb"
  owner "root"
  group "root"
  mode 0664
  if node['services']['enabled'] == "true"
    notifies :enable, "service[node_exporter]"
  end
  notifies :restart, "service[node_exporter]"
end

kagent_config "node_exporter" do
  action :systemd_reload
end

if node['kagent']['enabled'] == "true"
   kagent_config "node_exporter" do
     service "Monitoring"
     restart_agent false
   end
end

# If the machine has GPUs, configure the nvml_monitor.py
if node['cuda']['accept_nvidia_download_terms'].eql?("true")

  cookbook_file "#{node['node_exporter']['base_dir']}/nvml_monitor.py" do
    source 'nvml_monitor.py'
    owner node['hopsmonitor']['user']
    group node['hopsmonitor']['group']
    mode '0700'
    action :create
  end

  directory node['node_exporter']['text_metrics'] do
    owner node['hopsmonitor']['user']
    group node['hopsmonitor']['group']
    mode '0700'
    action :create
  end

  case node['platform_family']
  when "rhel"
    systemd_script = "/usr/lib/systemd/system/nvml_monitor.service" 
  else
    systemd_script = "/lib/systemd/system/nvml_monitor.service"
  end
  
  service "nvml_monitor" do
    provider Chef::Provider::Service::Systemd
    supports :restart => true, :stop => true, :start => true, :status => true
    action :nothing
  end
  
  template systemd_script do
    source "nvml_monitor.service.erb"
    owner "root"
    group "root"
    mode 0664
    if node['services']['enabled'] == "true"
      notifies :enable, "service[nvml_monitor]"
    end
    notifies :restart, "service[nvml_monitor]"
  end
  
  kagent_config "nvml_monitor" do
    action :systemd_reload
  end

  if node['kagent']['enabled'] == "true"
     kagent_config "nvml_monitor" do
       service "Monitoring"
       restart_agent false
     end
  end
end