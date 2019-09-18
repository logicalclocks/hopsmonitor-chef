s = "telegraf"
bash "kill_running_service_#{s}" do
  user "root"
  ignore_failure true
  code <<-EOF
    service #{s} stop
    service #{s} disable
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

directory node['telegraf']['home'] do
  action :delete
  ignore_failure true
end
