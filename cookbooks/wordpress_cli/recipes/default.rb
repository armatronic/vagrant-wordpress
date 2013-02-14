# Wordpress CLI installation
# https://github.com/wp-cli/wp-cli
include_recipe "git"
include_recipe "apache2"
include_recipe "mysql::server"
include_recipe "php"
include_recipe "php::module_mysql"
include_recipe "apache2::mod_php5"


# Set up Wordpress CLI.
config  = node[:wordpress]
command = "#{config[:cli_install_dir]}/bin/wp"
git config[:cli_install_dir] do
  repository        "git://github.com/wp-cli/wp-cli.git"
  reference         "master"
  action            :sync
  enable_submodules true
end


# Create the Wordpress install directory.
directory config[:dir] do
  action    :create
  recursive true
end


# Create the wordpress database.
# Need a less complex way of setting up a database than this.
execute "mysql-install-wp-privileges" do
  command "/usr/bin/mysql -u root -p\"#{node['mysql']['server_root_password']}\" < #{node['mysql']['conf_dir']}/wp-grants.sql"
  action :nothing
end
# Write template for database settings
template "#{node['mysql']['conf_dir']}/wp-grants.sql" do
  source "grants.sql.erb"
  owner "root"
  group "root"
  mode "0600"
  variables(
    :user     => node['wordpress']['db']['user'],
    :password => node['wordpress']['db']['password'],
    :database => node['wordpress']['db']['database']
  )
  notifies :run, "execute[mysql-install-wp-privileges]", :immediately
end
# Install mysql gem (required for checking if database exists)
gem_package "mysql" do
  action :install
end
# Create database.
execute "create #{node['wordpress']['db']['database']} database" do
  command "/usr/bin/mysqladmin -u root -p\"#{node['mysql']['server_root_password']}\" create #{node['wordpress']['db']['database']}"
  not_if do
    # Make sure gem is detected if it was just installed earlier in this recipe
    require 'rubygems'
    Gem.clear_paths
    require 'mysql'
    m = Mysql.new("localhost", "root", node['mysql']['server_root_password'])
    m.list_dbs.include?(node['wordpress']['db']['database'])
  end
  notifies :create, "ruby_block[save node data]", :immediately unless Chef::Config[:solo]
end
# save node data after writing the MYSQL root password, so that a failed chef-client run that gets this far doesn't cause an unknown password to get applied to the box without being saved in the node data.
unless Chef::Config[:solo]
  ruby_block "save node data" do
    block do
      node.save
    end
    action :create
  end
end


# Run the installer in this directory.
execute "#{command} core download" do
  cwd     config[:dir]
  action  :run
  creates "#{config[:dir]}/wp-load.php"
end


# Set up the web app as before.
# Set it up before configuration, because the config and install steps rely upon
# the site being configured.
if node.has_key?("ec2")
  server_fqdn = node['ec2']['public_hostname']
else
  server_fqdn = node['fqdn']
end
web_app "wordpress" do
  template "wordpress.conf.erb"
  docroot "#{node['wordpress']['dir']}"
  server_name server_fqdn
  server_aliases node['wordpress']['server_aliases']
end


# Configure the Wordpress install with the user password.
execute "#{command} core config \
  --dbname=\"#{config[:db][:database]}\" \
  --dbuser=\"#{config[:db][:user]}\" \
  --dbpass=\"#{config[:db][:password]}\"" do
  cwd    config[:dir]
  action :run
end


execute "#{command} core is-installed" do
  action :nothing
  # ignore_failure true
  returns [0,1]
end
# Which directory should it be installed to?
log(node.ipaddress)
execute "#{command} core install \
  --url=\"#{config[:url]}\" \
  --title=\"Wordpress site\" \
  --admin_email=\"admin@localhost.localdomain\" \
  --admin_name=\"admin\" \
  --admin_password=\"admin\"" do
  cwd    config[:dir]
  action :run
  # 1 means that the blog is already installed, so ignore that.
  returns [0,1]
  # This command returns 0 if installed, 1 if not.
  #only_if "#{command} core is-installed"
end


config[:cli_commands].each do |cli_command|
  execute "#{command} #{cli_command}" do
    cwd    config[:dir]
    action :run
  end
end
