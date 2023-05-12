include_recipe "hopsmonitor::_security"

#
# Prometheus installation
# 

base_package_filename = File.basename(node['prometheus']['url'])
cached_package_filename = "#{Chef::Config['file_cache_path']}/#{base_package_filename}"
alertmanagers= node['hopsmonitor'].attribute?('alertmanager')? private_recipe_ips('hopsmonitor', 'alertmanager') : []

remote_file cached_package_filename do
  source node['prometheus']['url']
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

directory node['prometheus']['data_volume']['root_dir'] do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode '0750'
  action :create
end

directory node['prometheus']['data_volume']['data_dir'] do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode '0750'
  action :create
end

bash 'Move prometheus data to data volume' do
  user 'root'
  code <<-EOH
    set -e
    mv -f #{node['prometheus']['data_dir']}/* #{node['prometheus']['data_volume']['data_dir']}
    rm -rf #{node['prometheus']['data_dir']}
  EOH
  only_if { conda_helpers.is_upgrade }
  only_if { File.directory?(node['prometheus']['data_dir'])}
  not_if { File.symlink?(node['prometheus']['data_dir'])}
end

link node['prometheus']['data_dir'] do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode '0750'
  to node['prometheus']['data_volume']['data_dir']
end

prometheus_downloaded= "#{node['prometheus']['home']}/.prometheus.extracted_#{node['prometheus']['version']}"
# Extract prometheus 
bash 'extract_prometheus' do
  user "root"
  code <<-EOH
    tar -xf #{cached_package_filename} -C #{node['prometheus']['root_dir']}
    chown -R #{node['hopsmonitor']['user']}:#{node['hopsmonitor']['group']} #{node['prometheus']['home']}
    chmod -R 750 #{node['prometheus']['home']}
    touch #{prometheus_downloaded}
    chown #{node['hopsmonitor']['user']} #{prometheus_downloaded}
  EOH
  not_if { ::File.exists?( prometheus_downloaded ) }
end

link node['prometheus']['base_dir'] do
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  to node['prometheus']['home']
end

crypto_dir = x509_helper.get_crypto_dir(node['hopsmonitor']['user'])
certificate = "#{crypto_dir}/#{x509_helper.get_certificate_bundle_name(node['hopsmonitor']['user'])}"
key = "#{crypto_dir}/#{x509_helper.get_private_key_pkcs8_name(node['hopsmonitor']['user'])}"
hops_ca = "#{crypto_dir}/#{x509_helper.get_hops_ca_bundle_name()}"
#check if installation for managed cloud, aka: enterprise installation and installing the cloud recipe 
managed_cloud = is_managed_cloud()

kube_certs_dir           = "#{crypto_dir}/kube"
prometheus_kube_key_path = "#{kube_certs_dir}/hopsmon.key"
prometheus_kube_crt_path = "#{kube_certs_dir}/hopsmon.crt"
kube_ca_path             = "#{kube_certs_dir}/kube_ca.pem"

kube_cluster_master_ip = ""

if (node["install"]["kubernetes"].casecmp? "true") && (!managed_cloud)
  begin
    kube_cluster_master_ip = private_recipe_ip('kube-hops', 'master')
  rescue
    raise "could not find the master ip for the kubernetes cluster"
  end

  if node['hopsmonitor']['prometheus']['kube-crt'].eql? ""
    raise "No cert received from kube-hops::hopsmon"
  end

  directory kube_certs_dir do
    owner node["kagent"]["certs_user"]
    group node["kagent"]["certs_user"]
    action :create
    mode '0700'
  end

  bash "kube_certs_dir_permissions" do
    user "root"
    code <<-EOH
    setfacl -m u:#{node['hopsmonitor']['user']}:rx #{kube_certs_dir}
    EOH
    only_if { File.directory?(kube_certs_dir)}
  end

  # Create the certificate files in the kube_certs_dir
  file prometheus_kube_crt_path do
    content node['hopsmonitor']['prometheus']['kube-crt']
    mode '0600'
    owner node["kagent"]["certs_user"]
    group node["kagent"]["certs_group"]
  end

  file prometheus_kube_key_path do
    content node['hopsmonitor']['prometheus']['kube-key']
    mode '0600'
    owner node["kagent"]["certs_user"]
    group node["kagent"]["certs_group"]
  end

  file kube_ca_path do
    content node['hopsmonitor']['prometheus']['kube-ca']
    mode '0600'
    owner node["kagent"]["certs_user"]
    group node["kagent"]["certs_group"]
  end

  bash "kube_certs_permissions" do
    user "root"
    code <<-EOH
    setfacl -m u:#{node['hopsmonitor']['user']}:rx #{kube_certs_dir}/*
    EOH
    only_if { File.directory?(kube_certs_dir)}
  end
end

template "#{node['prometheus']['base_dir']}/prometheus.yml" do
  source "prometheus.yml.erb"
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode '0700'
  action :create
  variables({
              'alertmanagers' => alertmanagers,
              'certificate' => certificate,
              'key' => key,
              'hops_ca' => hops_ca,
              'managed_cloud' => managed_cloud,
              'kube_master_ip' => kube_cluster_master_ip,
              'prometheus_kube_key'  => prometheus_kube_key_path,
              'prometheus_kube_crt' => prometheus_kube_crt_path,
              'kube_ca'              => kube_ca_path
            })
end

# Recreate the rules directory
directory node['prometheus']['rules_dir'] do 
  action :delete
  recursive true 
end

directory node['prometheus']['rules_dir'] do
  action :create
  owner node['hopsmonitor']['user']
  group node['hopsmonitor']['group']
  mode 0700
end

rules = [
  "hive",
  "consul",
  "hopsworks",
  "kafka",
  "onlinefs",
  "opensearch",
  "db",
  "hopsfs",
  "yarn",
  "host"
].each { |rule_file|
  template "#{node['prometheus']['rules_dir']}/#{rule_file}.rules.yml" do
    source "rules/#{rule_file}.rules.yml.erb"
    owner node['hopsmonitor']['user']
    group node['hopsmonitor']['group']
    mode 0700
  end
}

case node['platform_family']
when "rhel"
  systemd_script = "/usr/lib/systemd/system/prometheus.service" 
else
  systemd_script = "/lib/systemd/system/prometheus.service"
end

service "prometheus" do
  provider Chef::Provider::Service::Systemd
  supports :restart => true, :stop => true, :start => true, :status => true
  action :nothing
end

template systemd_script do
  source "prometheus.service.erb"
  owner "root"
  group "root"
  mode 0664
  if node['services']['enabled'] == "true"
    notifies :enable, "service[prometheus]"
  end
  notifies :restart, "service[prometheus]"
end

kagent_config "prometheus" do
  action :systemd_reload
end

if node['kagent']['enabled'] == "true"
   kagent_config "prometheus" do
     service "Monitoring"
     restart_agent false 
   end
end

if service_discovery_enabled()
  # Register Prometheus with Consul
  consul_service "Registering Prometheus with Consul" do
    service_definition "prometheus-consul.hcl.erb"
    action :register
  end
end 
