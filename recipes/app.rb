#
# Cookbook Name:: netcalc
# Recipe:: app
#
# Copyright (C) 2014 Chris Antenesse
# 
# All rights reserved - Do Not Redistribute
#


node.default["serf"]["version"] = '0.4.5'
node.default["serf"]["agent"]["tags"]["apps"] = 'netcalc'
node.default["serf"]["agent"]["tags"]["netcalc"] = node[:netcalc][:version]

include_recipe "apt"
include_recipe "python"
include_recipe "serf"

group "tornado" do
  group_name "tornado"
  gid 2000
  action :remove
  action :create
end

user "tornado" do
  username "tornado"
  home "/home/tornado"
  uid 2000
  gid 2000
  action :remove
  action :create
  supports ({ :manage_home => true })
end

template "/etc/init/netcalc.conf" do
  source "netcalc-upstart.conf.erb"
  mode 0444
  owner "root"
  group "root"
end

node[:netcalc][:python][:packages].each do |package|
  package "python-" + package
end

node[:netcalc][:python][:pip_packages].each do |pip|
  python_pip pip
end

package 'unzip' do
	action :install
end

remote_file "#{Chef::Config[:file_cache_path]}/netcalc-#{node[:netcalc][:version]}.zip" do
  source node[:netcalc][:package_source]
end

directory "/home/tornado/netcalc/app/" do
  owner 'tornado'
  group 'tornado'
  recursive true
  action :create
end

bash 'extract_app' do
  cwd "/home/tornado/netcalc/app/"
  code <<-EOH
    unzip #{Chef::Config[:file_cache_path]}/netcalc-#{node[:netcalc][:version]}.zip
    mv -fv netcalc-#{node[:netcalc][:version]}/* .
    rm -rfv netcalc-#{node[:netcalc][:version]}/
    EOH
  not_if { ::File.exists?('/home/tornado/netcalc/app/netcalc_listener.py') }
end

file "/home/tornado/netcalc/app/netcalc_listener.py" do
  mode 00777
end

service "netcalc" do
  provider Chef::Provider::Service::Upstart
  supports :restart => true, :status => true
  action [:enable, :start]
end
