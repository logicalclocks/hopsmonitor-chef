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
depends 'kkafka'
depends 'hive2'
depends 'hops_airflow'
depends 'epipe'
depends 'tensorflow'

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

#
#  Prometheus
# 
attribute "prometheus/retention_time",
          :description => "Retention time for prometheus data",
          :type => "string"

attribute "prometheus/port",
          :description => "Port on which prometheus listens",
          :type => "string"

#
# Alertmanager
# 
attribute "alertmanager/port",
          :description => "port on which alertmanager listens",
          :type => "string"

attribute "alertmanager/slack/api_url",
          :description => "Slack api url for sending alerts to slack",
          :type => "string"
attribute "alertmanager/slack/channel",
          :description => "Slack channel",
          :type => "string"
attribute "alertmanager/slack/username",        
          :description => "Slack bot username",
          :type => "string"
attribute "alertmanager/slack/text",       
          :description => "Slack text template",
          :type => "string"

attribute "alertmanager/email/to",
          :description => "Email address to send alerts to",
          :type => "string"
attribute "alertmanager/email/from",
          :description => "Email address to send alerts from",
          :type => "string"
attribute "alertmanager/email/smtp_host", 
          :description => "Smtp host",
          :type => "string"
attribute "alertmanager/email/auth_username",
          :description => "Email auth username",
          :type => "string"
attribute "alertmanager/email/auth_password",
          :description => "Email auth password",
          :type => "string"
attribute "alertmanager/email/auth_secret",
          :description => "Email auth secret",
          :type => "string"
attribute "alertmanager/email/auth_identity",
          :description => "Email auth identity",
          :type => "string"
attribute "alertmanager/email/text",
          :description => "Email text template",
          :type => "string"
