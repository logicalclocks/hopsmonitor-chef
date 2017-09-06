
services=[ 'grafana', 'telegraf', 'kapacitor', 'influxdb' ] 

for s in services
  bash "kill_running_service_#{s}" do
    user "root"
    ignore_failure true
    code <<-EOF
      service #{s} stop
    EOF
  end

  file "/etc/init.d/#{s}" do
    action :delete
    ignore_failure true
  end
  
  file "/usr/lib/systemd/system/#{s}.service" do
    action :delete
    ignore_failure true
  end
  file "/lib/systemd/system/#{s}service" do
    action :delete
    ignore_failure true
  end

  directory node["#{s}"]['home'] do
    recursive true
    action :delete
    ignore_failure true
  end

  link node["#{s}"]['base_dir'] do
    action :delete
    ignore_failure true
  end  
end
