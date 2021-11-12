#
# Grafana installation
#

base_package_filename = File.basename(node['grafana']['url'])
cached_package_filename = "#{Chef::Config['file_cache_path']}/#{base_package_filename}"

remote_file cached_package_filename do
  source node['grafana']['url']
  owner "root"
  mode "0644"
  action :create_if_missing
  retries 2
  retry_delay 5
end


grafana_downloaded = "#{node['grafana']['home']}/.grafana.extracted_#{node['grafana']['version']}"
# Extract grafana
bash 'extract_grafana' do
        user "root"
        code <<-EOH
                tar -xf #{cached_package_filename} -C #{node['hopsmonitor']['dir']}
                chown -R #{node['hopsmonitor']['user']}:#{node['hopsmonitor']['group']} #{node['grafana']['home']}
                chmod 750 #{node['grafana']['home']}
                touch #{grafana_downloaded}
                chown #{node['hopsmonitor']['user']} #{grafana_downloaded}

        EOH
     not_if { ::File.exists?( grafana_downloaded ) }
end

link node['grafana']['base_dir'] do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  to node['grafana']['home']
end

file "#{node['grafana']['base_dir']}/conf/sample.ini" do
  action :delete
end

my_private_ip = my_private_ip()
public_ip=my_public_ip()

directory "#{node['grafana']['base_dir']}/dashboards" do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode "750"
  action :create
end

directory "#{node['grafana']['base_dir']}/data" do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode "750"
  action :create
end

directory "#{node['grafana']['base_dir']}/logs" do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode "750"
  action :create
end


template "#{node['grafana']['base_dir']}/conf/defaults.ini" do
  source "grafana.ini.erb"
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode 0650
  variables({
     :public_ip => public_ip
  })
end

# Replace all the dashboards
directory "#{node['grafana']['base_dir']}/conf/provisioning/dashboards/rondb" do
  action :delete
  recursive true
end

remote_directory "#{node['grafana']['base_dir']}/conf/provisioning/dashboards/rondb" do 
  source "dashboards/rondb"
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode 0700
end

directory "#{node['grafana']['base_dir']}/conf/provisioning/dashboards/hops" do
  action :delete
  recursive true
end

remote_directory "#{node['grafana']['base_dir']}/conf/provisioning/dashboards/hops" do 
  source "dashboards/hops"
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode 0700
end

template "#{node['grafana']['base_dir']}/conf/provisioning/dashboards/provisioning.yaml" do 
  source "dashboards_provisioning.yml.erb"
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode 0700
end

directory "#{node['grafana']['base_dir']}/conf/provisioning/datasources" do 
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode 0700
  action :create
end

template "#{node['grafana']['base_dir']}/conf/provisioning/datasources/provisioning.yaml" do 
  source "datasources_provisioning.yml.erb"
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  variables ({
    'prometheus' => consul_helper.get_service_fqdn("prometheus"),
  })
  mode 0700
end

service_name="grafana"
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

if node['services']['enabled'] == "true"
  notifies :enable, resources(:service => service_name)
end
  notifies :restart, resources(:service => service_name)
end

kagent_config "#{service_name}" do
  action :systemd_reload
end

if node['kagent']['enabled'] == "true"
   kagent_config service_name do
     service "Monitoring"
     log_file "#{node['grafana']['base_dir']}/logs/grafana.log"
   end
end

if service_discovery_enabled()
  # Register Grafana with Consul
  consul_service "Registering Grafana with Consul" do
    service_definition "grafana-consul.hcl.erb"
    action :register
  end
end 
