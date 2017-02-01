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


#
# Setup influxdb for use with Hopsworks
#

dbname = 'graphite'
exec = "#{node.influxdb.base_dir}/bin/influx"
exec_pwd = "#{exec} -username #{node.influxdb.admin_user} -password #{node.influxdb.admin_password} -execute"

# Create a test cluster admin
execute 'create_adminuser' do
  command "#{exec} -execute \"CREATE USER #{node.influxdb.admin_user} WITH PASSWORD '#{node.influxdb.admin_password}' WITH ALL PRIVILEGES\""
#  not_if "#{exec_pwd} "
#  not_if "#{exec_pwd} 'show users' | grep #{node.influxdb.admin_user}"
end

# Create a test database
execute 'create_grahpitedb' do
  command "#{exec_pwd} \"CREATE DATABASE #{dbname}\""
end


# Create a test user and give it access to the test database
execute 'create_hopsworksuser' do
  command "#{exec_pwd} \"CREATE USER #{node.influxdb.db_user} WITH PASSWORD '#{node.influxdb.db_password}'\""
end
execute 'add_hopsworksuser_to_graphite' do
  command "#{exec_pwd} \"GRANT ALL ON #{dbname} TO #{node.influxdb.db_user}\""
end

# Create a test retention policy on the test database
execute 'add_retention_policy_to_graphite' do
  command "#{exec_pwd} \"CREATE RETENTION POLICY one_week ON #{dbname} DURATION 1w REPLICATION 1\""
end

if node.kagent.enabled == "true" 
   kagent_config "influxdb" do
     service "influxdb"
     log_file "/var/log/influxdb.log"
   end
end


