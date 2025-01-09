Vagrant.configure("2") do |config|
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
            if ! command -v docker; then
                sudo apt-get install -y docker.io
            fi
            swarm_output=$(sudo docker swarm init --advertise-addr eth1)
            swarm_token=$(echo "$swarm_output" | grep "SWMTKN" | awk '{print $5}')
            echo "$swarm_token" > /vagrant/swarm-token
        SHELL
    end

    ["node01", "node02", "node03"].each do |node_name|
        config.vm.define node_name do |node|
            node.vm.box = "ubuntu/bionic64"
            node.vm.network "private_network", type: "dhcp"
            node.vm.hostname = node_name
            node.vm.provider "virtualbox" do |v|
                v.memory = 1024
                v.cpus = 1
            end
            node.vm.provision "shell", inline: <<-SHELL
                sudo apt-get update
                if ! command -v docker; then
                    sudo apt-get install -y docker.io
                fi
                swarm_token=$(cat /vagrant/swarm-token)
                sudo docker swarm join --token $swarm_token 192.168.33.10:2377
            SHELL
        end
    end
end
