# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "hellocode/ruby-devenv64"

  config.vm.network "private_network", ip: "192.168.50.4"
  config.ssh.forward_agent = true

  config.vm.network "forwarded_port", guest: 3000, host: 3000
  config.vm.network "forwarded_port", guest: 3443, host: 3443

  # Default shared folder, just using nfs.
  config.vm.synced_folder ".", "/vagrant", type: "nfs"

  # Setup the environment
  config.vm.provision "shell", path: "scripts/setup.sh"

  config.vm.provider "virtualbox" do |v|
    v.name = "Chopeo Development Environment"
  end
end
