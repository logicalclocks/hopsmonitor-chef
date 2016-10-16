  bash 'kill_running_service' do
    user "root"
    ignore_failure true
    code <<-EOF
      service stop grafana
      systemctl stop grafana
      service stop graphite-web
      systemctl stop graphite-web
    EOF
  end

  file "/etc/init.d/grafana" do
    action :delete
    ignore_failure true
  end
  
  file "/usr/lib/systemd/system/grafana.service" do
    action :delete
    ignore_failure true
  end
  file "/lib/systemd/system/grafana.service" do
    action :delete
    ignore_failure true
  end

  directory node[:grafana][:home] do
    recursive true
    action :delete
    ignore_failure true
  end

