my_private_ip = my_private_ip()


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






package_url = "#{node.influxdb.url}"
base_package_filename = File.basename(package_url)
cached_package_filename = "/tmp/#{base_package_filename}"

remote_file cached_package_filename do
  source package_url
  owner "root"
  mode "0644"
  action :create_if_missing
end


influxdb_downloaded = "#{node.influxdb.home}/.influxdb.extracted_#{node.influxdb.version}"
# Extract influxdb
bash 'extract_influxdb' do
        user "root"
        code <<-EOH
                tar -xf #{cached_package_filename} -C #{node.hopsmonitor.dir}
                cd #{node.influxdb.home}
                mkdir bin
                mv usr/bin/* bin/
                             
                chown -R #{node.hopsmonitor.user}:#{node.hopsmonitor.group} #{node.influxdb.home}
                touch #{influxdb_downloaded}
                chown #{node.hopsmonitor.user} #{influxdb_downloaded}
                
        EOH
     not_if { ::File.exists?( influxdb_downloaded ) }
end

file node.influxdb.base_dir do
  action :delete
  force_unlink true
end

link node.influxdb.base_dir do
  owner node.hopsmonitor.user
  group node.hopsmonitor.group
  to node.influxdb.home
end


directory "#{node.influxdb.base_dir}/log" do
  owner node.hopsmonitor.user
  group node.hopsmonitor.group
  mode "750"
  action :create
end


directory "#{node.influxdb.conf_dir}" do
  owner node.hopsmonitor.user
  group node.hopsmonitor.group
  mode "750"
  action :create
  recursive true
end

directory "/var/log/influxdb" do
  owner node.hopsmonitor.user
  group node.hopsmonitor.group
  mode "750"
  action :create
end

