# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-18.04"
  [
    'starter',
    'full',
  ].each do |name|
    config.vm.define name do |x|
      x.vm.provider "virtualbox" do |v|
        v.memory = 2048
        v.cpus = 2
      end
      x.vm.provision "ansible_local" do |ansible|
        ansible.compatibility_mode = "2.0"
        ansible.become = false
        ansible.playbook = "playbook-#{name}.yml"
        ansible.skip_tags = "skip"
      end
    end
  end
end
