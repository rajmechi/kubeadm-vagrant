IMAGE_NAME = "centos/7"

# MASTER vm's
M=3

Vagrant.configure('2') do |configmaster|
  configmaster.vm.synced_folder '.', '/vagrant', disabled: true
  
  (1..M).each do |i|
        configmaster.vm.define "master-#{i}" do |master|
            master.vm.box = IMAGE_NAME
            master.vm.network "private_network", ip: "192.168.56.#{i + 120}"
            master.vm.hostname = "master#{i}.mykubecluster.com"
            master.vm.provider "virtualbox" do |v|
                v.memory = "2048"
                v.cpus = "2"
            end
            master.vm.provision "file", source: "kube-pre-req.sh", destination: "/tmp/run-pre-req.sh"
            master.vm.provision "file", source: "run.sh", destination: "/tmp/run.sh"
            master.vm.provision "shell",
                inline: "/bin/sh /tmp/run.sh"
   end

end 

end


# NODE vm's
N=2

Vagrant.configure('2') do |config1|
  config1.vm.synced_folder '.', '/vagrant', disabled: true

  (1..N).each do |i|
        config1.vm.define "node-#{i}" do |node|
            node.vm.box = IMAGE_NAME
            node.vm.network "private_network", ip: "192.168.56.#{i + 120 + M}"
            #node.vm.network "public_network", ip: "10.0.0.234"
            node.vm.hostname = "node#{i}.mykubecluster.com"
            node.vm.provider "virtualbox" do |v|
                v.memory = "2048"
                v.cpus = "1"
            end
            node.vm.provision "file", source: "kube-pre-req.sh", destination: "/tmp/run-pre-req.sh"
            node.vm.provision "file", source: "run.sh", destination: "/tmp/run.sh"
            node.vm.provision "shell",
                inline: "/bin/sh /tmp/run.sh"
   end

end 

end

# LOADBALANCER  vm's
L=1

Vagrant.configure('2') do |config2|
  config2.vm.synced_folder '.', '/vagrant', disabled: true

  (1..L).each do |i|
        config2.vm.define "lb-#{i}" do |lb|
            lb.vm.box = IMAGE_NAME
            lb.vm.network "private_network", ip: "192.168.56.#{i + 120 + M + N}"
            lb.vm.hostname = "kubeapi.mykubecluster.com"
            lb.vm.provider "virtualbox" do |v|
                v.memory = "2048"
                v.cpus = "1"
            end
            lb.vm.provision "file", source: "lb.sh", destination: "/tmp/run-lb.sh"
            lb.vm.provision "shell",
                inline: "/bin/sh /tmp/run-lb.sh"
   end

end 

end





#lb.vm.network "public_network", adapter: "1",  type: "dhcp"
#lb.vm.network "private_network", type: "dhcp"
#lb.vm.network "public_network", use_dhcp_assigned_default_route: true
#lb.vm.network "public_network", ip: "10.0.0.234"