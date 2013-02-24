# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "ubuntu1204"

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  # config.vm.box_url = "http://domain.com/path/to/above.box"

  # Boot with a GUI so you can see the screen. (Default is headless)
  # config.vm.boot_mode = :gui

  # Assign this VM to a host-only network IP, allowing you to access it
  # via the IP. Host-only networks can talk to the host machine as well as
  # any other machines on the same network, but cannot be accessed (through this
  # network interface) by any external networks.
  config.vm.network :hostonly, "192.168.33.10"

  # Assign this VM to a bridged network, allowing you to connect directly to a
  # network using the host's network device. This makes the VM appear as another
  # physical device on your network.
  # config.vm.network :bridged

  # Forward a port from the guest to the host, which allows for outside
  # computers to access the VM, whereas host only networking does not.
  config.vm.forward_port 80, 4567

  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = "cookbooks"
    chef.json = {
      :ubuntu => {
        :archive_url             => "http://au.archive.ubuntu.com/ubuntu/",
        :security_url            => "http://au.archive.ubuntu.com/ubuntu/",
        :include_source_packages => false,
      },
      :mysql => {
        :server_root_password   => "something",
        :server_repl_password   => "something",
        :server_debian_password => "something",
      },
      :wordpress => {
        :cli_install_dir => "/opt/wp-cli",
        :site_title      => "Wordpress Site",
        # Should default to FQDN if not otherwise set.
        :url             => "192.168.33.10",
        :admin           => {
          # Leave @ off? add FQDN or URL to end.
          :email    => 'admin@localhost.localdomain',
          :user     => 'admin',
          :password => 'admin',
        },
        :db => {
          :password => 'blah'
        },
        :cli_commands => [],
      },
      :wordpress_cli => {
        # Uses same commands as wordpress install CLI?
        :cli_install_dir => "/opt/wp-cli",
      }
    }
    chef.add_recipe "ubuntu"
    chef.add_recipe "wordpress::install_cli"
  end
end
