group node['hopsmonitor']['group'] do
  action :create
  not_if "getent group #{node['hopsmonitor']['group']}"
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

user node['hopsmonitor']['user'] do
  gid node['hopsmonitor']['group']
  action :create
  system true
  shell "/bin/bash"
  not_if "getent passwd #{node['hopsmonitor']['user']}"
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

group node['hopsmonitor']['group'] do
  action :modify
  members ["#{node['hopsmonitor']['user']}"]
  append true
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end