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
grafana_run_permission = "#{node['grafana']['home']}/.grafana.run_permission_#{node['grafana']['version']}"
# Extract grafana
bash 'extract_grafana' do
        user "root"
        code <<-EOH
                tar -xf #{cached_package_filename} -C #{node['hopsmonitor']['dir']}
                chown -R #{node['hopsmonitor']['user']}:#{node['hopsmonitor']['group']} #{node['grafana']['home']}
                chmod 750 #{node['grafana']['home']}
                touch #{grafana_downloaded}
                chown #{node['hopsmonitor']['user']} #{grafana_downloaded}
                touch #{grafana_run_permission}
                chown #{node['hopsmonitor']['user']} #{grafana_run_permission}

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

managed_cloud = is_managed_cloud()
if !managed_cloud
  directory "#{node['grafana']['base_dir']}/conf/provisioning/dashboards/kserve" do
    action :delete
    recursive true
  end

  remote_directory "#{node['grafana']['base_dir']}/conf/provisioning/dashboards/kserve" do
    source "dashboards/kserve"
    owner node['hopsmonitor']['user']
    group node['hopsmonitor']['group']
    mode 0700
  end

  directory "#{node['grafana']['base_dir']}/conf/provisioning/dashboards/kubernetes" do
    action :delete
    recursive true
  end

  remote_directory "#{node['grafana']['base_dir']}/conf/provisioning/dashboards/kubernetes" do
    source "dashboards/kubernetes"
    owner node['hopsmonitor']['user']
    group node['hopsmonitor']['group']
    mode 0700
  end
end

template "#{node['grafana']['base_dir']}/conf/provisioning/dashboards/provisioning.yaml" do 
  source "dashboards_provisioning.yml.erb"
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode 0700
  variables({
    :managed_cloud => managed_cloud
 })
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

#chef_sleep '10' ? if grafana is not up yet
dashboards_with_viewer_permission = node['grafana']['dashboard']['viewer_permission']
bash 'set_dashboard_permissions' do
  user "root"
  code <<-EOH
    FOLDERS=$(curl -u #{node['grafana']['admin_user']}:#{node['grafana']['admin_password']} \
                   --request GET \
                   #{public_ip}:#{node['grafana']['port']}/api/folders | jq -r .[].uid)

    for uid in ${FOLDERS}; do
      curl -u #{node['grafana']['admin_user']}:#{node['grafana']['admin_password']} \
        --header "Content-Type: application/json" \
        --request POST \
        --data '{"items": []}'\
        #{public_ip}:#{node['grafana']['port']}/api/folders/${uid}/permissions
    done

    for uid in #{dashboards_with_viewer_permission}; do
      curl -u #{node['grafana']['admin_user']}:#{node['grafana']['admin_password']} \
        --header "Content-Type: application/json" \
        --request POST \
        --data '{"items": [{ "role": "Viewer", "permission": 1 }]}' \
        #{public_ip}:#{node['grafana']['port']}/api/dashboards/uid/${uid}/permissions
    done
    rm #{grafana_run_permission}
    touch "#{grafana_run_permission}_done"
  EOH
  only_if { ::File.exists?( grafana_run_permission ) }
end
