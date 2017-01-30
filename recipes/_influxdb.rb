my_private_ip = my_private_ip()


template"#{node.influxdb.conf_dir}/influxdb.conf" do
  source "influxdb.conf.erb"
  owner node.hopsmonitor.user
  group node.hopsmonitor.group
  mode 0650
  variables({ 
     :my_ip => my_private_ip
           })
end

case node.platform
when "ubuntu"
 if node.platform_version.to_f <= 14.04
   node.override.influxdb.systemd = "false"
 end
end


service_name="influxdb"

if node.influxdb.systemd == "true"

  service service_name do
    provider Chef::Provider::Service::Systemd
    supports :restart => true, :stop => true, :start => true, :status => true
    action :nothing
  end

  case node.platform_family
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
    notifies :start, resources(:service => service_name), :immediately
  end

  kagent_config "reload_influxdb_daemon" do
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
    owner node.hopsmonitor.user
    group node.hopsmonitor.group
    mode 0754
    notifies :enable, resources(:service => service_name)
    notifies :restart, resources(:service => service_name), :immediately
  end

end


# case node.platform_family
#   when "debian"
#     package "ruby-dev"
#   when "rhel"
#     package "ruby-devel" 
# end


dbname = 'graphite'

# Create a test cluster admin
execute 'create_adminuser' do
  command "#{node.influxdb.base_dir}/bin/influx -execute \"CREATE USER #{node.influxdb.admin_user} WITH PASSWORD '#{node.influxdb.admin_password}'\""
end

# Create a test database
execute 'create_grahpitedb' do
  command "#{node.influxdb.base_dir}/bin/influx -username #{node.influxdb.admin_user} -password #{node.influxdb.admin_password} -execute \"CREATE DATABASE graphite\""
end


# Create a test user and give it access to the test database
execute 'create_hopsworksuser' do
  command "#{node.influxdb.base_dir}/bin/influx -username #{node.influxdb.admin_user} -password #{node.influxdb.admin_password} -execute \"CREATE USER hopsworks WITH PASSWORD 'hopsworks'\""
end
execute 'add_hopsworksuser_to_graphite' do
  command "#{node.influxdb.base_dir}/bin/influx -username #{node.influxdb.admin_user} -password #{node.influxdb.admin_password} -execute \"GRANT ALL ON graphite TO hopsworks\""
end

# Create a test retention policy on the test database
execute 'add_retention_policy_to_graphite' do
  command "#{node.influxdb.base_dir}/bin/influx -username #{node.influxdb.admin_user} -password #{node.influxdb.admin_password} -execute \"CREATE RETENTION POLICY one_week ON graphite DURATION 1w REPLICATIOn 1\""
end

if node.kagent.enabled == "true" 
   kagent_config "influxdb" do
     service "influxdb"
     log_file "/var/log/influxdb.log"
   end
end


