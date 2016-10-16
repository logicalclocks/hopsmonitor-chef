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
depends 'graphite'
#depends 'runit'
#depends 'grafana'
#depends 'influxdb'
#depends 'apt'
#depends 'yum'
#depends 'nginx'

recipe "hopsmonitor::install", "Installs Kibana Server"
recipe "hopsmonitor::default", "configures Kibana Server"
recipe "hopsmonitor::purge", "Deletes the Kibana Server"

attribute "hopsmonitor/user",
          :description => "User to run Kibana server as",
          :type => "string"

attribute "hopsmonitor/group",
          :description => "Group to run Kibana server as",
          :type => "string"


