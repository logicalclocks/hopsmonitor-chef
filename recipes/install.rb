
user node.hopsmonitor.user do
  home "/home/#{node.hopsmonitor.user}"
  action :create
  system true
  shell "/bin/bash"
  manage_home true
  not_if "getent passwd #{node.hopsmonitor.user}"
end

group node.hopsmonitor.group do
  action :modify
  members ["#{node.hopsmonitor.user}"]
  append true
end


include_recipe "java"

