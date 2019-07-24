maintainer       "Jim Dowling"
maintainer_email "jdowling@kth.se"
name             "hopsmonitor"
license          "AGPLv3"
description      "Deploy monitoring infrastructure for the Hopsworks platform"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "1.0.0"
source_url       "https://github.com/logicalclocks/hopsmonitor-chef"

%w{ ubuntu debian centos }.each do |os|
  supports os
end

depends 'conda'
depends 'java'
depends 'kagent'
depends 'hops'
depends 'ndb'
depends 'elastic'

recipe "hopsmonitor::install", "Installs Influxdb/Grafana Server"
recipe "hopsmonitor::default", "configures Influxdb/Grafana Server"
recipe "hopsmonitor::influxdb", "Installs and configure InfluxDb"
recipe "hopsmonitor::grafana", "Installs and configure Grafana"
recipe "hopsmonitor::prometheus", "Installs and configure Prometheus"
recipe "hopsmonitor::node_exporter", "Installs and configure node exporter"
recipe "hopsmonitor::purge", "Deletes the Influxdb/Grafana Server"

attribute "hopsmonitor/user",
          :description => "User to run Influxdb/Grafana server as",
          :type => "string"

attribute "hopsmonitor/group",
          :description => "Group to run Influxdb/Grafana server as",
          :type => "string"

attribute "hopsmonitor/dir",
          :description => "Base install directory for Influxdb/Grafana ",
          :type => "string"

attribute "hopsmonitor/default/private_ips",
          :description => "Set ip addresses",
          :type => "array"

attribute "hopsmonitor/default/public_ips",
          :description => "Set ip addresses",
          :type => "array"

attribute "hopsmonitor/private_ips",
          :description => "Set ip addresses",
          :type => "array"

attribute "hopsmonitor/public_ips",
          :description => "Set ip addresses",
          :type => "array"

#
# InfluxDB
#

attribute "influxdb/db_user",
          :description => "username for influxdb account used by hopsworks ",
          :type => "string"

attribute "influxdb/db_password",
          :description => "Password for influxdb account used by hopsworks",
          :type => "string"

attribute "influxdb/admin_user",
          :description => "username for influxdb admin ",
          :type => "string"

attribute "influxdb/admin_password",
          :description => "Password for influxdb admin user",
          :type => "string"


attribute "influxdb/http/port",
          :description => "Http port for influxdb",
          :type => "string"

attribute "influxdb/port",
          :description => "Main port for influxdb",
          :type => "string"

attribute "influxdb/admin/port",
          :description => "Admin port for influxdb",
          :type => "string"

attribute "influxdb/graphite/port",
          :description => "Port for influxdb graphite connector",
          :type => "string"

#
# Grafana
#

attribute "grafana/admin_user",
          :description => "username for grafana admin ",
          :type => "string"

attribute "grafana/admin_password",
          :description => "Password for grafana admin user",
          :type => "string"

attribute "grafana/port",
          :description => "Port for grafana",
          :type => "string"