include_attribute "kagent"

default['hopsmonitor']['user']                    = node['install']['user'].empty? ? "hopsmon" : node['install']['user']
default['hopsmonitor']['group']                   = node['install']['user'].empty? ? "hopsmon" : node['install']['user']


default['hopsmonitor']['dir']                     = node['install']['dir'].empty? ? "/srv" : node['install']['dir']

default['influxdb']['version']                    = "1.2.1"
# https://dl.influxdata.com/influxdb/releases/influxdb-1.1.1_linux_amd64.tar.gz
default['influxdb']['url']                        = "#{node['download_url']}/influxdb-#{node['influxdb']['version']}_linux_amd64.tar.gz"

default['influxdb']['db_user']                    = "hopsworks"
default['influxdb']['db_password']                = "hopsworks"
default['influxdb']['telegraf_user']              = "telegraf"
default['influxdb']['telegraf_password']          = "telegraf"
default['influxdb']['admin_user']                 = "adminuser"
default['influxdb']['admin_password']             = "adminpw"

default['influxdb']['databases']                  = %w{ graphite telegraf }

# The default port is '8088' in influxdb (for backup/restore). This conflicts with yarn::rm, so we change it below
default['influxdb']['port']                       = "9999"
default['influxdb']['admin']['port']              = "8084"
default['influxdb']['http']['port']               = "8086"

default['influxdb']['home']                       = node['hopsmonitor']['dir'] + "/influxdb-" + "#{node['influxdb']['version']}-1"
default['influxdb']['base_dir']                   = node['hopsmonitor']['dir'] + "/influxdb"
default['influxdb']['conf_dir']                   = node['influxdb']['base_dir'] + "/conf"
default['influxdb']['pid_file']                   = "/tmp/influxdb.pid"
default['influxdb']['graphite']['port']           = "2003"
default['influxdb']['series']['max']              = 0

default['grafana']['version']                     = "6.2.4"
default['grafana']['url']                         = "#{node['download_url']}/grafana-#{node['grafana']['version']}.linux-amd64.tar.gz"
default['grafana']['port']                        = 3000

default['grafana']['admin_user']                  = "adminuser"
default['grafana']['admin_password']              = "adminpw"

default['grafana']['mysql_user']                  = "grafana"
default['grafana']['mysql_password']              = "grafana"

default['grafana']['home']                        = node['hopsmonitor']['dir'] + "/grafana-" + "#{node['grafana']['version']}"
default['grafana']['base_dir']                    = node['hopsmonitor']['dir'] + "/grafana"
default['grafana']['pid_file']                    = "/tmp/grafana.pid"