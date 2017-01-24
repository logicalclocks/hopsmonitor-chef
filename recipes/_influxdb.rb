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


#include_recipe 'influxdb::default'

include_recipe 'influxdb::ruby_client'

dbname = 'graphite'

# node.override['influxdb']['config'] =
# {
#     'bind-address' => "#{my_private_ip}:#{node.influxdb.port}",
#     "meta" => {
#         "dir" => "#{node.influxdb.base_dir}/meta",
#         'retention-autocreate' => true,
#         'logging-enabled' => true
#     },
#     "data" => {
#         "dir" => "#{node.influxdb.base_dir}/data",
#         "wal-dir" => "#{node.influxdb.base_dir}/wal",
#         'engine' => 'tsm1',
#         'wal-logging-enabled' => true,
#         'query-log-enabled' => true,
#         'cache-max-memory-size' => 524_288_000,
#         'cache-snapshot-memory-size' => 26_214_400,
#         'cache-snapshot-write-cold-duration' => '1h0m0s',
#         'compact-full-write-cold-duration' => '24h0m0s',
#         'max-points-per-block' => 0,
#         'trace-logging-enabled' => false
#     },
#     'coordinator' => {
#       'write-timeout' => '10s',
#       'max-concurrent-queries' => 0,
#       'query-timeout' => '0',
#       'log-queries-after' => '0',
#       'max-select-point' => 0,
#       'max-select-series' => 0,
#       'max-select-buckets' => 0
#     }, 
#    'retention' => {
#       'enabled' => true,
#       'check-interval' => '30m0s'
#     },
#    'shard-precreation' => {
#       'enabled' => true,
#       'check-interval' => '10m0s',
#       'advance-period' => '30m0s'
#     },
#     'admin' => {
#         'enabled' => true,
#         'bind-address' => ':8083',
#         'https-enabled' => false,
#         'https-certificate' => node['influxdb']['ssl_cert_file_path'],
#     },
#       'monitor' => {
#         'store-enabled' => true,
#         'store-database' => '_internal',
#         'store-interval' => '10s',
#       },
#       'subscriber' => {
#         'enabled' => true,
#         'http-timeout' => '30s',
#       },
#       'http' => {
#         'enabled' => true,
#         'bind-address' => ':8086',
#         'auth-enabled' => false,
#         'log-enabled' => true,
#         'write-tracing' => false,
#         'pprof-enabled' => false,
#         'https-enabled' => false,
#         'https-certificate' => node['influxdb']['ssl_cert_file_path'],
#         'https-private-key' => '',
#         'max-row-limt' => 10_000,
#         'max-connection-limit' => 0,
#         'shared-secret' => '',
#         'realm' => 'InfluDB',
#       }, 
#   'graphite' => [{
#         'enabled' => true,
#         'bind-address' => "#{my_private_ip}:2003",
#         'conprotocol' => "tcp",
#     }],
#   'continuous_queries' => {
#     'log-enabled' => true,
#     'enabled' => true,
#     'run-interval' => '1s',
#   }


# }


# influxdb_install 'influxdb' do
#   arch_type 'amd64' # if undefined will auto detect
#   include_repository true # default
#   influxdb_key 'https://repos.influxdata.com/influxdb.key' # default
#   action :install # default
# end

# service 'influxdb' do
#   action :nothing
# end


# influxdb_config node['influxdb']['config_file_path'] do
#   path node.influxdb.base_dir + "/conf"
#   config node['influxdb']['config']
#   action :create
#   notifies :restart, 'service[influxdb]'
# end


# Create a test database
influxdb_database dbname do
  action :create
end


# Create a test user and give it access to the test database
influxdb_user node.influxdb.db_user do
  password node.influxdb.db_password
  databases [dbname]
  api_hostname my_private_ip
  api_port 8086
  use_ssl false
  verify_ssl false
  action :create
end

# Create a test cluster admin
influxdb_admin node.influxdb.admin_user do
  password node.influxdb.admin_password
  action :create
end


# Create a test retention policy on the test database
influxdb_retention_policy 'test_policy' do
  policy_name 'one_week'
  database dbname
  duration '1w'
  replication 1
  # by default in v1.0 there's a policy named autogen that is created for any
  # db, when `meta.retention-autocreate`=true. We will make this test_policy
  # the default policy.
  # ref1: https://docs.influxdata.com/influxdb/v1.0/query_language/database_management/#retention-policy-management
  # ref2: https://docs.influxdata.com/influxdb/v1.0/administration/config/#meta
  default true
  action :create
  notifies :restart, 'service[influxdb]'
end


if node.kagent.enabled == "true" 
   kagent_config "influxdb" do
     service "influxdb"
     log_file "/var/log/influxdb.log"
   end
end


