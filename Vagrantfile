# -*- mode: ruby -*-
# vi: set ft=ruby :

MACHINES = {
  :ipaserver => {
    :box_name => "centos/7",
    :vm_name => "ipaserver",
    :ip => '192.168.50.10',
    :mem => '2048'
  },
  :ipaclient => {
    :box_name => "centos/7",
    :vm_name => "ipaclient",
    :ip => '192.168.50.11',
    :mem => '1048'
  }
}
Vagrant.configure("2") do |config|
  MACHINES.each do |boxname, boxconfig|
    config.vm.define boxname do |box|
      box.vm.box = boxconfig[:box_name]
      box.vm.host_name = boxname.to_s
      box.vm.network "private_network", ip: boxconfig[:ip]
      box.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--memory", boxconfig[:mem]]
      end
      if boxconfig[:vm_name] == "ipaclient"
        box.vm.provision "ansible" do |ansible|
          ansible.playbook = "ansible/playbook.yml"
          ansible.inventory_path = "ansible/hosts"
          ansible.become = true
#          ansible.verbose = "vvv"
          ansible.host_key_checking = "false"
          ansible.limit = "all"
        end
      end
    end
  end
end
