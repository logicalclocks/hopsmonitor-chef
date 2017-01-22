include_attribute "kagent"

default.hopsmonitor.user                     = "graphite"
default.hopsmonitor.group                    = "graphite"


default.hopsmonitor.dir                      = "/srv"



default.influxdb.version                    = "1.1.1"
# https://dl.influxdata.com/influxdb/releases/influxdb-1.1.1_linux_amd64.tar.gz
default.influxdb.url                        = "#{node.download_url}/influxdb-#{node.influxdb.version}_linux_amd64.tar.gz"
default.influxdb.port                       = "9999"

default.influxdb.systemd                    = "true"
default.influxdb.home                       = node.hopsmonitor.dir + "/influxdb-" + "#{node.influxdb.version}-1"
default.influxdb.base_dir                   = node.hopsmonitor.dir + "/influxdb"
default.influxdb.pid_file                   = "/tmp/influxdb.pid"



default.grafana.version                    = ""
default.grafana.url                        = "#{node.download_url}/grafana-#{node.grafana.version}_linux_amd64.tar.gz"
default.grafana.port                       = "9999"

default.grafana.systemd                    = "true"
default.grafana.home                       = node.hopsmonitor.dir + "/grafana-" + "#{node.grafana.version}-1"
default.grafana.base_dir                   = node.hopsmonitor.dir + "/grafana"
default.grafana.pid_file                   = "/tmp/grafana.pid"

