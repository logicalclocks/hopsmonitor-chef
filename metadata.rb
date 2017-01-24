maintainer       "Jim Dowling"
maintainer_email "jdowling@kth.se"
name             "hopsmonitor"
license          "Apache v2.0"
description      "Installs/Configures a HopsFS to ElasticSearch connector"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.1"
source_url       "https://github.com/hopshadoop/hopsmonitor-chef"

%w{ ubuntu debian centos }.each do |os|
  supports os
end

depends 'java'
depends 'kagent'
#depends 'chef-grafana'
depends 'elastic'
depends 'influxdb'
depends 'ndb'

#depends 'runit'
#depends 'grafana'
#depends 'apt'
#depends 'yum'
#depends 'nginx'

recipe "hopsmonitor::install", "Installs Influxdb/Grafana Server"
recipe "hopsmonitor::default", "configures Influxdb/Grafana Server"
recipe "hopsmonitor::purge", "Deletes the Influxdb/Grafana Server"

attribute "hopsmonitor/user",
          :description => "User to run Influxdb/Grafana server as",
          :type => "string"

attribute "hopsmonitor/group",
          :description => "Group to run Influxdb/Grafana server as",
          :type => "string"


attribute "grafana/admin_user",
          :description => "username for grafana admin ",
          :type => "string"

attribute "grafana/admin_password",
          :description => "Password for grafana admin user",
          :type => "string"


attribute "grafana/mysql_user",
          :description => "username for grafana mysql user ",
          :type => "string"

attribute "grafana/mysql_password",
          :description => "Password for grafana mysql user",
          :type => "string"

