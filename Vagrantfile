#
# A basic Vagrantfile to go with manifests/vagrant.pp for testing
#
# Requires the foillowing modules to exist in ../ :
# 
#     puppet-stdlib
#     (epel : for centos only)
# 
Vagrant.configure("2") do |config|
  config.vm.hostname = "puppet-graphite"

  # uncomment for your distribution of choice
  #config.vm.box = "ubuntu-server-12042-x64-vbox4210.box"
  #config.vm.box_url = "http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210.box"
  config.vm.box = "centos-65-x64-virtualbox-puppet.box"
  config.vm.box_url = "http://puppet-vagrant-boxes.puppetlabs.com/centos-65-x64-virtualbox-puppet.box"
  #config.vm.box = "debian-73-x64-virtualbox-puppet.box"  # debian currently does not work
  #config.vm.box_url = "http://puppet-vagrant-boxes.puppetlabs.com/debian-73-x64-virtualbox-puppet.box"

  config.vm.network :private_network, ip: "192.168.191.10"
  config.vm.synced_folder "templates/", "/tmp/vagrant-puppet/templates"

  config.vm.provision "puppet" do |puppet|
    puppet.manifests_path = "manifests"
    puppet.manifest_file = "vagrant.pp"
    puppet.module_path = "../"  
    puppet.options = ["--templatedir","/tmp/vagrant-puppet/templates"]
  end
end
