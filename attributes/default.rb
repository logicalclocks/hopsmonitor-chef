include_attribute "kagent"
include_attribute "consul"
include_attribute "hops"
include_attribute "ndb"
include_attribute "tensorflow"
include_attribute "hops_airflow"

default['hopsmonitor']['user']                    = node['install']['user'].empty? ? "hopsmon" : node['install']['user']
default['hopsmonitor']['group']                   = node['install']['user'].empty? ? "hopsmon" : node['install']['user']

default['hopsmonitor']['dir']                     = node['install']['dir'].empty? ? "/srv" : node['install']['dir']

default['influxdb']['version']                    = "1.2.1"
# https://dl.influxdata.com/influxdb/releases/influxdb-1.1.1_linux_amd64.tar.gz
default['influxdb']['url']                        = "#{node['download_url']}/influxdb-#{node['influxdb']['version']}_linux_amd64.tar.gz"

default['influxdb']['db_user']                    = "hopsworks"
default['influxdb']['db_password']                = "hopsworks"
default['influxdb']['admin_user']                 = "adminuser"
default['influxdb']['admin_password']             = "adminpw"

default['influxdb']['databases']                  = %w{ graphite }

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

default['grafana']['home']                        = node['hopsmonitor']['dir'] + "/grafana-" + "#{node['grafana']['version']}"
default['grafana']['base_dir']                    = node['hopsmonitor']['dir'] + "/grafana"
default['grafana']['pid_file']                    = "/tmp/grafana.pid"

# Default prometheus port is 9090, but we run Karamel on that port. 
default['prometheus']['port']                     = "9089"
default['prometheus']['version']                  = "2.10.0"
default['prometheus']['url']                      = "#{node['download_url']}/prometheus/prometheus-#{node['prometheus']['version']}.linux-amd64.tar.gz"
default['prometheus']['root_dir']                 = "#{node['hopsmonitor']['dir']}/prometheus"

default['prometheus']['home']                     = "#{node['prometheus']['root_dir']}/prometheus-#{node['prometheus']['version']}.linux-amd64"
default['prometheus']['base_dir']                 = "#{node['prometheus']['root_dir']}/prometheus"
default['prometheus']['data_dir']                 = "#{node['prometheus']['root_dir']}/prometheus-data"
default['prometheus']['retention_time']           = "15d"
default['prometheus']['rules_dir']                = "#{node['prometheus']['base_dir']}/alerting-rules"

default['node_exporter']['version']               = "0.18.1"
default['node_exporter']['url']                   = "#{node['download_url']}/prometheus/node_exporter-#{node['node_exporter']['version']}.linux-amd64.tar.gz"
default['node_exporter']['port']                  = "9100"
default['node_exporter']['home']                  = "#{node['prometheus']['root_dir']}/node_exporter-#{node['node_exporter']['version']}.linux-amd64"
default['node_exporter']['base_dir']              = "#{node['prometheus']['root_dir']}/node_exporter"
default['node_exporter']['filesystem']['regex']   = "^/(dev|proc|sys|var/lib/docker/.+)($|/)"
default['node_exporter']["text_metrics"]          = "#{default['node_exporter']['base_dir']}/text_metrics" 

default['alertmanager']['port']                     = "9093"
default['alertmanager']['version']                  = "0.17.0"
default['alertmanager']['url']                      = "#{node['download_url']}/prometheus/alertmanager-#{node['alertmanager']['version']}.linux-amd64.tar.gz"
default['alertmanager']['root_dir']                 = "#{node['hopsmonitor']['dir']}/alertmanager"

default['alertmanager']['home']                     = "#{node['alertmanager']['root_dir']}/alertmanager-#{node['alertmanager']['version']}.linux-amd64"
default['alertmanager']['base_dir']                 = "#{node['alertmanager']['root_dir']}/alertmanager"
default['alertmanager']['data_dir']                 = "#{node['alertmanager']['root_dir']}/alertmanager-data"
default['alertmanager']['retention_time']           = "15d"

# Alertmanager slack configuration
default['alertmanager']['slack']['api_url']         = ""
default['alertmanager']['slack']['channel']         = ""
default['alertmanager']['slack']['username']        = "alertmanager"
default['alertmanager']['slack']['text']            = "<!channel> \nsummary: {{ .CommonAnnotations.summary }}\ndescription: {{ .CommonAnnotations.description }}"

# Alertmanager email configuration
default['alertmanager']['email']['to']              = ""             
default['alertmanager']['email']['from']            = "" 
default['alertmanager']['email']['smtp_host']       = "" 
default['alertmanager']['email']['auth_username']   = "" 
default['alertmanager']['email']['auth_password']   = "" 
default['alertmanager']['email']['auth_secret']     = "" 
default['alertmanager']['email']['auth_identity']   = "" 
default['alertmanager']['email']['text']            = "summary: {{ .CommonAnnotations.summary }}\ndescription: {{ .CommonAnnotations.description }}"