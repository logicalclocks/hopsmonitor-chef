my_private_ip = my_private_ip()
my_public_ip = my_public_ip()



# Don't install nginx on port 80
# node.override['grafana']['webserver'] = ''
# node.override['grafana']['home'] = '/srv/grafana'
# node.override['grafana']['data_dir'] = '/srv/grafana-data'
# #node.override['grafana']['conf_dir'] = node.grafana.home
# node.override['grafana']['webserver_port'] = 9999

#include_recipe "chef-grafana::default"


# grafana_datasource 'graphite-test' do
#   datasource(
#     type: 'graphite',
#     url: 'http://10.0.0.15:8080',
#     access: 'direct'
#   )
# end



include_recipe "hopsmonitor::_influxdb"
#include_recipe "_grafana"
