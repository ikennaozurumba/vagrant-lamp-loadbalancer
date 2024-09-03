#!/bin/bash

# deploy.sh: script to automate the deployment of a LAMP stack on a master and Slave node as well as a reverse proxy load balancer


# set -ex
set -e

#================================================================================================
# Ensure the script is run with root privileges
#================================================================================================

if [[ "$(id -u)" -ne 0 ]]; then # if the identity of the user is not root, 
	sudo -E "$0" "$@"  # then, run the script with sudo priviledges preserving the environment variables
	exit
fi


#================================================================================================
# Log stdout to a file named deploy.log and any errors to a file named deploy_err.log
#================================================================================================

shared_dir="/vagrant"
log_stdout="$shared_dir/deploy.log"
log_error="$shared_dir/deploy_err.log"
exec > >(tee -a $log_stdout) 2> >(tee -a $log_error >&2)


#================================================================================================
# commence logging of output
#================================================================================================
echo ".................loggging output started at $(date)......................................."



#================================================================================================
# Install relevant repositories to Advanced Package Tool Manager
#================================================================================================
echo "....................Adding Relevant Repositories to APT manager............................."
sudo apt-get install -y software-properties-common apt-transport-https ca-certificates curl gnupg gpg
sudo add-apt-repository -y ppa:ondrej/php
sudo apt-get update


#================================================================================================
# Check if the hypervisor (VirtualBox) is installed
#================================================================================================
if command -v VBoxManage --version > /dev/null; then
       	echo "...........Oracle VM VirtualBox manager is installed.........................."
else
	echo "................Oracle VM VirtualBox Manager is not installed................."
	echo "............Installing VirtualBox............................................."

	# Adding the Oracle VirtualBox repository to sources.list.d
	echo "..............Adding VirtualBox repository to source.list.d..................."
	DISTRO=$(lsb_release -cs)  # determining the distribution codename
	echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian $DISTRO contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
	
	# Download and add the Oracle public key
	echo "................Downloading and adding Oracle public key......................"
	wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg --dearmor

	# Update the package list
        echo ".......................Updating package list................................."
	sudo apt-get update
	# Install VirtualBox
	echo ".........................Installing VirtualBox.............................."
	sudo apt-get install -y virtualbox-7.0

	# Confirm installation
	if command -v VBoxManage --version > /dev/null; then
		echo "-------Oracle VM VirtualBox manager installed successfully.------------"
	else
		echo "-------Failed to install Oracle VM VirtualBox manager.------------"
		exit 1
	fi
fi



#================================================================================================
# check if the VM provider (vagrant) is installed
#================================================================================================
if command -v vagrant > /dev/null; then
      	echo .........................."Vagrant is installed...................................."
else
	echo ".........................Vagrant is not installed, installing vagrant............."
	# Adding the Hashicorp GPG key
	curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
	
	# Adding official Hashicorp repository
	echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
	
	# Updating the package list
        sudo apt-get update
    
	# Installing Vagrant
	sudo apt-get install -y vagrant

	# Confirming installation
	if command -v vagrant > /dev/null; then
		echo "...........................Vagrant installed successfully.........................."
	else
		echo ".........................Failed to install Vagrant................................."
		exit 1
	fi
fi

#===================================================================================================
#===================================================================================================
#===================================================================================================



#===================================================================================================
# Vagrantfile configuration for master and slave node
#===================================================================================================

# Check if Vagrantfile exists
if [ -e "Vagrantfile" ]; then
	echo ".........Vagrantfile already exists, overwriting its content.........................."
else
	echo "...........Vagrantfile does not exist, creating Vagrantfile.........................."
	vagrant init || exit
fi

# Overwrite or create Vagrantfile with the desired configuration

cat > Vagrantfile <<-__EOF__
# -*- mode: ruby -*-
# vi set ft=ruby :

# Configuration for Ubuntu Servers (master and slave node) and nginx loadbalancer

Vagrant.configure("2") do |config|

  # Define a common base box for both VMs
  config.vm.box = "ubuntu/focal64"

  # Define the load balancer node
  config.vm.define "loadbalancer" do |lb|
    lb.vm.hostname = "loadbalancer"
    lb.vm.network "private_network", ip: "192.168.33.18"

    # VM provider configuration
    lb.vm.provider "virtualbox" do |v|
      v.name = "loadbalancer"
      v.memory = 1024
      v.cpus = 1
    end


    # Provisioning script for loadbalancer
    lb.vm.provision "shell", inline: <<-SHELL
      echo "............Provisioning the load balancer node..........."

      # Update APT and install nginx
      sudo apt-get update
      sudo apt-get install -y nginx

      echo ".......Configuring nginx as a load balancer................"
      sudo tee /etc/nginx/sites-available/default > /dev/null <<-EOL
        upstream lamp_cluster {
            server 192.168.33.16; # master node ip
            server 192.168.33.17; # slave node ip
        }


        server {
            listen 80;
            
            location / {
		proxy_pass http://lamp_cluster;
		proxy_set_header Host \$host;
		proxy_set_header X-Real-IP \$remote_addr;
		proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        	proxy_set_header X-Forwarded-Proto \$scheme;
            }
        }
      EOL
    SHELL
  end



  # Define the master node
  config.vm.define "master" do |m|
    m.vm.hostname = "master"
    m.vm.network "private_network", ip: "192.168.33.16"
    
    # VM provider configuration
    m.vm.provider "virtualbox" do |v|
      v.name = "master"
      v.memory = 1024
      v.cpus = 2
    end

    # Provisioning script for master node
    m.vm.provision "shell", inline: <<-SHELL
      echo "...................Provisioning the master node............................."      

      # update and upgrade packages
      sudo apt-get update && apt-get upgrade -y

      # creating a user: altschool
      echo "......creating a user called altschool with the appropriate privileges........."
      USERNAME="altschool"
      PASSWORD="$(openssl rand -base64 14)" # secure random password
      echo "........$USERNAME login password is: $PASSWORD................................"
      
      echo "........Generating secure hashed passwd using SHA-512 algorithm.........."
      PASSWORD_HASH="$(openssl passwd -6 "$PASSWORD")"

      sudo useradd -m -s /bin/bash -p "$PASSWORD_HASH" "$USERNAME"
      
      # checking if user altschool was created successfully
      if id "$USERNAME" &> /dev/null; then
          echo "............user: $USERNAME created successfully..............."
      else
          echo "...........Failed to create user: $USERNAME....................."
	  exit 1
      fi

      echo "....Granting altschool user root (superuser) privileges......."
      echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USERNAME > /dev/null


      # switch user to $USERNAME and generate ssh key for connection with slave node
      echo "......Generating id_rsa key for connection with the slave node........."
      su - $USERNAME -c ' 
      if [[ ! -f /home/$USERNAME/.ssh/id_rsa ]]; then
        sudo mkdir -p /home/$USERNAME/.ssh
        sudo chmod 700 /home/$USERNAME/.ssh
        ssh-keygen -t rsa -b 4096 -f /home/$USERNAME/.ssh/id_rsa -q -N ""
      fi

      # Ensure permission for ssh key files
      sudo chmod 600 /home/$USERNAME/.ssh/id_rsa
      sudo chmod 644 /home/$USERNAME/.ssh/id_rsa.pub
      sudo cp /home/$USERNAME/.ssh/id_rsa.pub /vagrant/id_rsa.pub


      # Copy the content of /mnt/altschool/ directory into the salve node
      echo "..........Creating a /mnt/altschool/ directory.............................."
      sudo mkdir -p -m 755 /mnt/$USERNAME/
      sudo chown -R $USERNAME:$USERNAME /mnt/$USERNAME/

      echo "..........Creating a test_data.txt in /mnt/altschool directory.............."
      echo "This is a sample data, created at: $(date +%y/%m/%d' '%H:%M:%S) UTC" | sudo tee /mnt/$USERNAME/test_data.txt > /dev/null

      sudo cp -R /mnt/$USERNAME/test_data.txt /vagrant
      '

      # Disable root login via ssh, set password auth to no, and enable pubkey auth
      sudo sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin no/' "/etc/ssh/sshd_config"
      sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' "/etc/ssh/sshd_config"
      sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' "/etc/ssh/sshd_config"
      sudo systemctl restart ssh || sudo service ssh restart


      # Install, configure, and enable Apache, PHP, and MySQL
      echo "...............Installing Apache, PHP, and MySQL........................."
      sudo apt-get update
      export DEBIAN_FRONTEND="noninteractive"

      echo "................Generating a random secure MySQL root password........................"
      MYSQL_ROOT_PASSWORD="$(openssl rand -base64 10)" # Secure random password

      echo "........MySQL root password is: $MYSQL_ROOT_PASSWORD................................"

      # Preconfigure MySQL password setup BEFORE installation
      sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD"
      sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD"

      
      sudo apt-get install -y apache2 mysql-server php libapache2-mod-php php-mysql

      # Starting and enabling Apache
      sudo systemctl start apache2
      sudo systemctl enable apache2

      # Secure MySQL installation
      echo ".................Disabling MySQL remote root login...................."
      sudo sed -i "s/.*bind-address.*/bind-address = 127.0.0.1/" /etc/mysql/mysql.conf.d/mysqld.cnf

      echo ".................Dropping the test database if it exists.........................."
      mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS test;" || true

      sudo systemctl restart mysql

      # Validate PHP functionality with Apache
      echo ".............validating php functionality....................................."
      echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php > /dev/null

      echo "..............PHP info script created at /var/www/html/info.php................"


      # indicate content is being served from master node
      echo "<h1>Served from Master Node</h1>" | sudo tee -a /var/www/html/index.html

      echo "....................restarting apache2 webserver............................................"
      sudo systemctl restart apache2


    SHELL

  end
    
  # Define the slave node config
  config.vm.define "slave" do |s|
    s.vm.hostname = "slave"
    s.vm.network "private_network", ip: "192.168.33.17"
      
    s.vm.provider "virtualbox" do |v|
      v.name = "slave"
      v.memory = 1024
      v.cpus = 1
    end
      
    # Provisioning script for slave node
    slave.vm.provision "shell", inline: <<-SHELL
      echo "..........Provisioning the slave node......................."
     
      # update and upgrade packages 
      sudo apt-get update && apt-get upgrade -y

      # Ensure .ssh directory exists
      mkdir -p /home/vagrant/.ssh
      sudo chmod 700 /home/vagrant/.ssh
      sudo chown -R vagrant:vagrant /home/vagrant/.ssh

      # Add master node altschool user public key to authorized_key file in the slave node
      echo ".............Adding id_rsa.pub key to the slave node......................."
      if ! grep -q "$(cat /vagrant/id_rsa.pub)" /home/vagrant/.ssh/authorized_keys 2>/dev/null; then
        echo -e "\n" | sudo tee -a /home/vagrant/.ssh/authorized_keys
        sudo cat /vagrant/id_rsa.pub | sudo tee -a /home/vagrant/.ssh/authorized_keys
        sudo chmod 600 /home/vagrant/.ssh/authorized_keys
        sudo chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
      fi
       

      sudo sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin no/' "/etc/ssh/sshd_config"
      sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' "/etc/ssh/sshd_config"
      sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' "/etc/ssh/sshd_config"
      sudo systemctl restart ssh || sudo service ssh restart



      # Copying the content of /mnt/altschool/ directory from vagrant into /mnt/altschool in the slave node
      echo "..........Creating a /mnt/altschool/ directory in the slave node.............................."
      sudo mkdir -p -m 755 /mnt/altschool/
      sudo chown -R vagrant:vagrant /mnt/altschool/


      if [[ -f /vagrant/test_data.txt ]]; then
          echo "test_data.txt exist in /vagrant directory"
          echo "copying test_data.txt to /mnt/altschool/ directory in the slave node"
          sudo cp /vagrant/test_data.txt   /mnt/altschool/
      else
          echo "Could not copy test_data.txt into /mnt/altschol directory"
      fi


      # Install, configure, and enable Apache, PHP, and MySQL on slave node
      echo "...............Installing Apache, PHP, and MySQL on slave node........................."
      sudo apt-get update
      export DEBIAN_FRONTEND="noninteractive"

      echo "................Generating a random secure MySQL root password........................"
      SQL_ROOT_PASSWORD="$(openssl rand -base64 12)" # Secure random password

      echo "........MySQL root password is: $SQL_ROOT_PASSWORD................................"

      # Preconfigure MySQL password setup BEFORE installation
      sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $SQL_ROOT_PASSWORD"
      sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $SQL_ROOT_PASSWORD"

      
      sudo apt-get install -y apache2 mysql-server php libapache2-mod-php php-mysql

      # Starting and enabling Apache
      sudo systemctl start apache2
      sudo systemctl enable apache2

      # Secure MySQL installation
      echo ".................Disabling MySQL remote root login...................."

      sudo sed -i "s/.*bind-address.*/bind-address = 127.0.0.1/" /etc/mysql/mysql.conf.d/mysqld.cnf

      echo ".................Dropping the test database if it exists.........................."
      mysql -uroot -p"$SQL_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS test;" || true

      sudo systemctl restart mysql

      # Validate PHP functionality with Apache
      echo ".............validating php functionality....................................."
      echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php > /dev/null

      echo "..............PHP info script created at /var/www/html/info.php................"


      # indicate content is being served from slave node 
      echo "<h1>Served from Slave Node</h1>" | sudo tee -a /var/www/html/index.html

      echo "....................restarting apache2 webserver............................................"
      sudo systemctl restart apache2

    SHELL
  end
  
end
__EOF__


# Start the virtual machines
vagrant up

# SSH into the master node
vagrant ssh master <<-EOL
  echo "Welcome to Master node VM"
    
  # Display the content of test_data.txt in the master node
  sudo cat /mnt/altschool/test_data.txt

  # Add a cron job for user 'altschool' to list processes on reboot
  sudo crontab -u altschool -l | { cat; echo "@reboot ps aux"; } | sudo crontab -u altschool -

  # SSH into the slave node from the master node and display the content of test_data.txt
  echo "Connecting to the slave node from the master node"
  ssh vagrant@192.168.33.17 <<-EOS
    echo "Welcome to \$(whoami) node"
    sudo cat /mnt/altschool/test_data.txt
    exit
  EOS
EOL

