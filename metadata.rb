maintainer       "Jim Dowling"
maintainer_email "jdowling@kth.se"
name             "hopsmonitor"
license          "AGPLv3"
description      "Deploy monitoring infrastructure for the Hopsworks platform"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.7.0"
source_url       "https://github.com/logicalclocks/hopsmonitor-chef"

%w{ ubuntu debian centos }.each do |os|
  supports os
end

depends 'conda'
depends 'hops'
depends 'ndb'
depends 'kagent'
depends 'tensorflow'
depends 'hops_airflow'
depends 'java'
depends 'kube-hops'
depends 'hive2'


recipe "hopsmonitor::install", "Installs Prometheus/Grafana Server"
recipe "hopsmonitor::default", "configures Grafana Server"
recipe "hopsmonitor::grafana", "Installs and configure Grafana"
recipe "hopsmonitor::prometheus", "Installs and configure Prometheus"
recipe "hopsmonitor::node_exporter", "Installs and configure node exporter"

attribute "hopsmonitor/user",
          :description => "User to run Prometheus/Grafana server as",
          :type => "string"

attribute "hopsmonitor/user_id",
          :description => "Monitor user id. Default: 1503",
          :type => "string"

attribute "hopsmonitor/group",
          :description => "Group to run Prometheus/Grafana server as",
          :type => "string"

attribute "hopsmonitor/group_id",
          :description => "Monitor group id. Default: 1503",
          :type => "string"

attribute "hopsmonitor/dir",
          :description => "Base install directory for Prometheus/Grafana ",
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

attribute "grafana/dashboard/viewer_permission",
          :description => "Space separated list of dashboard uids with viewer permission. Default: 'onlineFS user_statement_summaries kserve kubernetes'",
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

attribute "prometheus/rondb_replication_alert",
          :description => "Configure alerts for RonDB Global replication. Default: false",
          :type => "string"

#
# Alertmanager
# 
attribute "alertmanager/port",
          :description => "port on which alertmanager listens",
          :type => "string"

attribute "alertmanager/clustered",
          :description => "enables HA mode",
          :type => "string"
attribute "alertmanager/cluster/listen_address",
          :description => "alertmanager cluster listen address for communication with peers",
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

attribute "alertmanager/webhook/url",
          :description => "Webhook url configuration for alertmanager",
          :type => "string"

attribute "alertmanager/webhook/send_resolved",
          :description => "Webhook send_resolved configuration for alertmanager",
          :type => "string"

#
# Managed cloud
#
attribute "cloud/queue_config/capacity",
          :description => "capacit of the queue for sending metrics to hopsworks.ai",
          :type => "string"

attribute "cloud/queue_config/max_sample_per_send",
          :description => "maximum number of samples per metrics send to hopsworks.ai",
          :type => "string"

attribute "cloud/queue_config/batch_send_deadline",
          :description => "maximum time before a metric is sent to hopsworks.ai",
          :type => "string"

#
# node_exporter
#
attribute "node_exporter/filesystem/regex",
          :description => "Regular expression of filesystem mount point to ignore reporting",
          :type => "string"

attribute "node_exporter/port",
          :description => "Port node_exporter will be listening to. Default: 9100",
          :type => "string"

attribute "node_exporter/is-ndbmtd",
          :description => "Flag to indicate that this node_exporter is installed in a machine where ndbmtd is installed to. It controls consul's tags. Normally it will auto-discovered except the cases where node_exporter is installed in a separate cluster definition. Default: false",
          :type => "string"

attribute "prometheus/rules/all-hosts-available-mem-threshold",
          :description => "Percentage of minimum available memory for all but ndbmtd machines in the cluster, anything lower will fire an alert. Default: 10%",
          :type => "string"

attribute "prometheus/rules/ndbd-hosts-available-mem-threshold",
  :description => "Percentage of minimum available memory for ndbmtd only machines in the cluster, anything lower will fire an alert. Default: 1.5%",
          :type => "string"
