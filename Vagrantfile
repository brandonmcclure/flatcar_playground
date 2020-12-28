ENV["TERM"] = "xterm-256color"
ENV["LC_ALL"] = "en_US.UTF-8"

NODES_NUM = 3
NODES_CPU = 4
NODES_MEM = 4096
CHANNEL = "Alpha"

Vagrant.require_version '>= 2.0.4'

Vagrant.configure('2') do |config|
	config.ssh.username = 'core'
  	config.ssh.insert_key = true
	config.vm.provision "shell", path: "provision.sh"
	config.vm.synced_folder 'mountPoint', "/vagrant"
	(1..NODES_NUM).each do |i|  
		config.vm.define "core-#{i}" do |node|
			node.vm.box = "flatcar-#{CHANNEL}"
			node.vm.hostname = "core-#{i}"
			node.vm.network "forwarded_port", guest: 80, host: "#{i}80", auto_correct: false, id: "http"
			node.vm.network "forwarded_port", guest: 443, host: "#{i}443", auto_correct: false, id: "https"
			node.vm.provider :virtualbox do |v|
    			v.check_guest_additions = false
    			v.functional_vboxsf = false
    			v.cpus = NODES_CPU
				v.memory = NODES_MEM
		  		end
			end
  	end
  
end
