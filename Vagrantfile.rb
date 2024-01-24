Vagrant.configure("2") do |config|

    swarn_token = "SWMTKN-1-23456789abcdefgh0123456789abcdefgh0123456789abcdefgh0123456789abcdefgh"

    config.vm.define "master" do |master|
        master.vm.box = "ubuntu/bionic64"
        master.vm.network "private_network", type: "dhcp"
        master.vm.network "forwarded_port", guest: 2237, host: 2237

        master.vm.hostname = "master"
        master.vm.provider "virtualbox" do |v|
            v.memory = 1024
            v.cpus = 1
        end
        master.vm.provision "shell", inline: <<-SHELL
            sudo apt-get update
            sudo apt-get install -y docker.io

            sudo docker swarn init --advertise--addr eth1

            echo "#{swarn_token}" > /vagrant/swarn-token
            SHELL
        end
        
        ["node01", "node02", "node03"].each do |node_name|
            config.vm.define node_name do |node|
                node.vm.box = "ubutu/bionic64"
                node.vm.network "private_network", type: "dhcp"
                node.vm.hostname = node_name
                node.vm.provider "virtualbox" do |v|
                    v.memory = 1024
                    v.cpus = 1
                end
                node.vm.provision "shell", inline: <<-SHELL
                    sudo apt-get update
                    sudo apt-get install -y docker.io

                    swarn_token=$(cat /vagrant/swarn-token)

                    sudo docker swarn join --token $swarn_token master:2377
                SHELL
            end
        end
        
end
