# LAMP Stack Deployment with Reverse Proxy Load Balancer

This project automates the deployment of a LAMP (Linux, Apache, MySQL, PHP) stack across a master and slave node using Vagrant and VirtualBox. Additionally, it configures an Nginx reverse proxy load balancer to distribute traffic between the two nodes.

## Table of contents

1. [Project Overview](#Project-Overview)
   - [Objective](#Objective)
   - [Prerequisites](#Prerequisites)
3. [Deployment Instructions](#Deployment-Instructions)
4. [Code Files](#Code-files)
   - [deploy.sh](#deploy.sh)
5. [Log Files](#Log-files)
   - [deploy.log](#deploy.log)
   - [deploy_err.log](#deploy_err.log)
7. [Screenshots](#Screenshots)
   - [Screenshot of ControlNode and ManagedNode1 on VB](#Screenshot_of_ControlNode_and_ManagedNode1_on_VB)
9. [Usage](#Usage)
10. [Contributions](#Contributions)
11. [References](#References)


## [Project Overview](Project-Overview)

### [Objective](#Objective)

The objectives of this project is to develop a bash script that will do the following:

1. Infrastructure Configuration: Deploy two Ubuntu systems; a master node capable of acting as a control system and a slave node that will be managed by the Master node.

2. User Management: Create a user named altschool on the master node and grant this user root (superuser) privileges.

3. Inter-node Communication: SSH key-based authentication should enable the Master node (altschool user) seamlessly SSH into the Slave node without requiring a password.

4. Data Management and Transfer: On initiation, the bash script is expected to create a /mnt/altschool directory on the master node and copy the contents of this directory from the Master node to /mnt/altschool/slave on the Slave node. This operation should be performed using the altschool user from the Master node.

5. Process Monitoring: The Master node is expected to display an overview of the Linux process management, showcasing currently running processes.

6. LAMP Stack Deployment: The bash script is expected to install AMP (Apache, MySQL, PHP) stack on both nodes and ensure Apache is running and set to start on boot. It is also expected to Secure the MySQL installation and initialize it with a default user and password and validate PHP functionality with Apache.


### [Prerequisites](Prerequisites)

Before starting this deployment, ensure you have a UNIX-based operating system (e.g., Linux) installed and running on your local machine, as the `deploy.sh` script will only run in a UNIX environment. Alternatively, you can install and run Windows Subsystem for Linux (WSL), which provides a UNIX-like environment on Windows, allowing you to run Linux-based software, including shell scripts.


## [Deployment Instructions](Deployment-Instructions)

This section covers the content of the deploy.sh script, which handles the installation of Vagrant (the VM provider), VirtualBox (the hypervisor), the configuration of the Vagrantfile for the master, slave, and load balancer nodes, and the testing of the connection between the master and slave nodes upon running `vagrant up`. 

1. VirtualBox Installation: This script starts by ensuring the commands are ran with elevated (superuser) privileges, afterwhich relevant repositories are added to the APT (Advanced Package Tool) manager. Afterwards, the script checks if the hypervisor (VirtualBox) is present on the local machine before installing the latest version `virtualbox-7.0`.

```bash
#!/bin/bash

# deploy.sh: script to automate the deployment of a LAMP stack on a master and Slave node as well as a reverse proxy load balancer


# set -ex
set -e
.......

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
	DISTRO="$(lsb_release -cs)"  # determining the distribution codename
	echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian $DISTRO contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
	
	# Download and add the Oracle public key
	echo "................Downloading and adding Oracle public key......................"
	wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg --dearmor

	# Update the package list
        echo ".......................Updating package list................................."
	sudo apt-get update || { echo "Failed to update APT repositories after adding VirtualBox"; exit 1; }
# Install VirtualBox
	echo ".........................Installing VirtualBox.............................."
	sudo apt-get install -y virtualbox-7.0 || { echo "Failed to install VirtualBox"; exit 1; }


	# Confirm installation
	if command -v VBoxManage --version > /dev/null; then
		echo "-------Oracle VM VirtualBox manager installed successfully.------------"
	else
		echo "-------Failed to install Oracle VM VirtualBox manager.------------"
		exit 1
	fi
fi
```


2. Vagrant Installation: Next, the script also checks if the VM provider, vagrant, is present on the local machine before installing it from the official [Hashicorp repository](https://developer.hashicorp.com/vagrant).

```bash
#================================================================================================
# check if the VM provider (vagrant) is installed
#================================================================================================
if command -v vagrant > /dev/null; then
      	echo "..........................Vagrant is installed...................................."
else
	echo ".........................Vagrant is not installed, installing vagrant............."
	
	
	# Adding the Hashicorp GPG key
	curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg || { echo "Failed to add Hashicorp GPG Key"; exit 1; }

	
	# Adding official Hashicorp repository
	echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list || { echo "Failed to add Hashicorp repository"; exit 1 }
	
	# Updating the package list
        sudo apt-get update || { echo "Failed to update APT repo after adding Hashicorp repository"; exit 1; }
    
	# Installing Vagrant
	sudo apt-get install -y vagrant || { echo "Failed to install vagrant"; exit 1; }

	# Confirming installation
	if command -v vagrant > /dev/null; then
		echo "...........................Vagrant installed successfully.........................."
	else
		echo ".........................Failed to install Vagrant................................."
		exit 1
	fi
fi
```

3. Vagrantfile configuration: The script then configures and provisions the master, slave, and load balancer nodes, using `ubuntu/focal64` as the base box. SSh connection is established for secure connestion between the master and the slave nodes, LAMP stack is installed on both nodes, and a test_data.txt file created in the /mnt/altschool directory on the master node is copied to a /mnt/altschool/slave directory on the slave node. 

```bash
#===================================================================================================
# Vagrantfile configuration for master, slave, and loadbalancer nodes
#===================================================================================================

# Check if Vagrantfile exists
if [ -e "Vagrantfile" ]; then
	echo ".........Vagrantfile already exists, overwriting its content.........................."
else
	echo "...........Vagrantfile does not exist, creating Vagrantfile.........................."
	vagrant init || exit 1
fi


# Overwrite or create Vagrantfile with the desired configuration

cat > Vagrantfile <<-__EOF__
# -*- mode: ruby -*-
# vi set ft=ruby :

# Configuration for Ubuntu Servers (master and slave node) and nginx loadbalancer
Vagrant.configure("2") do |config|

  # Define a common base box for both VMs
  config.vm.box = "ubuntu/focal64"

.............
```


## [Code Files](Code-files)

### [deploy.sh](deploy.sh)

```ruby
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
sudo apt-get install -y software-properties-common apt-transport-https ca-certificates curl gnupg gpg || { echo "Failed to install initial dependencies"; exit 1;}

sudo add-apt-repository -y ppa:ondrej/php || { echo "Failed to add PHP repository"; exit 1; }

sudo apt-get update || { echo "Failed to update APT repositories"; exit 1; }


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
	DISTRO="$(lsb_release -cs)"  # determining the distribution codename
	echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian $DISTRO contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
	
	# Download and add the Oracle public key
	echo "................Downloading and adding Oracle public key......................"
	wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg --dearmor

	# Update the package list
        echo ".......................Updating package list................................."
	sudo apt-get update || { echo "Failed to update APT repositories after adding VirtualBox"; exit 1; }


	# Install VirtualBox
	echo ".........................Installing VirtualBox.............................."
	sudo apt-get install -y virtualbox-7.0 || { echo "Failed to install VirtualBox"; exit 1; }


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
      	echo "..........................Vagrant is installed...................................."
else
	echo ".........................Vagrant is not installed, installing vagrant............."
	
	
	# Adding the Hashicorp GPG key
	curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg || { echo "Failed to add Hashicorp GPG Key"; exit 1; }

	
	# Adding official Hashicorp repository
	echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list || { echo "Failed to add Hashicorp repository"; exit 1 }
	
	# Updating the package list
        sudo apt-get update || { echo "Failed to update APT repo after adding Hashicorp repository"; exit 1; }
    
	# Installing Vagrant
	sudo apt-get install -y vagrant || { echo "Failed to install vagrant"; exit 1; }

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
# Vagrantfile configuration for master, slave, and loadbalancer nodes
#===================================================================================================

# Check if Vagrantfile exists
if [ -e "Vagrantfile" ]; then
	echo ".........Vagrantfile already exists, overwriting its content.........................."
else
	echo "...........Vagrantfile does not exist, creating Vagrantfile.........................."
	vagrant init || exit 1
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
      sudo apt-get update || { echo "Failed to update APT repo before provisioning loadbalancer"; exit 1; }	

      sudo apt-get install -y nginx || { echo "Failed to install nginx"; exit 1; }

      echo "........Configuring nginx as a load balancer................"
      sudo tee /etc/nginx/sites-available/default > /dev/null <<-EOL
        upstream lamp_cluster {
            server 192.168.33.16; # master node ip
            server 192.168.33.17; # slave node ip
        }


        server {
            listen 80;
            
            location / {
		proxy_pass http://lamp_cluster;
		proxy_set_header Host $host;
		proxy_set_header X-Real-IP $remote_addr;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        	proxy_set_header X-Forwarded-Proto $scheme;
            }
        }
      EOL
      
      # Restart nginx
      echo ".......Restarting nginx to apply changes........"
      sudo systemctl restart nginx || { echo "Failed to restart nginx after config"; exit 1; }
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
      sudo apt-get update || { echo "Failed to update APT repo before provisioning master node"; exit 1; }
      sudo apt-get upgrade -y || { echo "Failed to upgrade packages before provisioning master node"; exit 1; } 


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
      sudo usermod -aG sudo "$USERNAME" || { echo "Failed to add user to sudo group"; exit 1; }

      # Create SSH directory and generate SSH keys
      sudo mkdir -p -m 700 "/home/$USERNAME/.ssh" || { echo "Failed to create SSH directory"; exit 1; }

      # Set correct ownership
      sudo chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.ssh"


      echo "............Generating SSH keys for the user: altschool................"
      sudo -u "$USERNAME" ssh-keygen -t rsa -N '' -f "/home/"$USERNAME"/.ssh/id_rsa" -C "$USERNAME" -q || { echo "Failed to generate SSH keys"; exit 1; }
      sudo chmod 600 "/home/$USERNAME/.ssh/id_rsa" || { echo "Failed to set permissions for private key"; exit 1; }
      sudo chmod 644 "/home/$USERNAME/.ssh/id_rsa.pub" || { echo "Failed to set permissions for public key"; exit 1; }
      

      # Copy id_rsa.pub key to the shared folder /vagrant for authentication with the slave node
      sudo cp "/home/$USERNAME/.ssh/id_rsa.pub" /vagrant/id_rsa.pub
      sudo chmod 644 /vagrant/id_rsa.pub || { echo "Failed to set permissions for /vagrant/id_rsa.pub"; exit 1; }
      echo "...............Successfully generated and copied SSH keys......................."



      # Create the /mnt/altschool/ directory and copy its content to the slave node
      echo ".........Creating a /mnt/altschool/ directory..................."
      
      sudo mkdir -p -m 755 "/mnt/$USERNAME/" || { echo "Failed to create directory /mnt/altschool"; exit 1; }
      sudo chown -R "$USERNAME:$USERNAME" "/mnt/$USERNAME/"


      echo "..........Creating a test_data.txt in /mnt/$USERNAME directory.............."
      sudo touch "/mnt/$USERNAME/test_data.txt"
      sudo chmod 755 "/mnt/$USERNAME/test_data.txt"
      echo "This is a sample data, created at: $(date +%y/%m/%d' '%H:%M:%S) UTC" | sudo tee "/mnt/$USERNAME/test_data.txt" > /dev/null
      sudo chown -R "$USERNAME:$USERNAME" "/mnt/$USERNAME/test_data.txt"


      sudo cp -R "/mnt/$USERNAME/test_data.txt" /vagrant
     

      # Disable root login via ssh, set password auth to no, and enable pubkey auth
      sudo sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin no/' "/etc/ssh/sshd_config"
      sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' "/etc/ssh/sshd_config"
      sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' "/etc/ssh/sshd_config"
      sudo systemctl restart ssh || { echo "Failed to restart ssh"; exit 1; }


      # Install, configure, and enable Apache, PHP, and MySQL
      echo "...............Installing Apache, PHP, and MySQL........................."
      sudo apt-get update || { echo "Failed to update before installing LAMP stack"; exit 1; }
      export DEBIAN_FRONTEND="noninteractive"

      echo "................Generating a random secure MySQL root password........................"
      MYSQL_ROOT_PASSWORD="$(openssl rand -base64 10)" # Secure random password

      echo "........MySQL root password is: $MYSQL_ROOT_PASSWORD................................"

      # Preconfigure MySQL password setup BEFORE installation
      sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD"
      sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD"

      
      sudo apt-get install -y apache2 mysql-server php libapache2-mod-php php-mysql || { echo "Failed to install LAMP stack"; exit 1; }


      echo "..........Enabling mod_rewrite for Apache................................"
      sudo a2enmod rewrite || true

      # Starting and enabling Apache
      sudo systemctl start apache2
      sudo systemctl enable apache2


      # Secure MySQL installation
      echo ".................Disabling MySQL remote root login...................."
      sudo sed -i "s/.*bind-address.*/bind-address = 127.0.0.1/" /etc/mysql/mysql.conf.d/mysqld.cnf

      sudo systemctl restart mysql || { echo "failed to restart mysql"; exit 1; }

      # Show databases
      mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SHOW DATABASES;" || true

      # Clean up package cache
      sudo apt-get clean || true


      # Validate PHP functionality with Apache
      echo ".............validating php functionality....................................."
      echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php > /dev/null

      echo "..............PHP info script created at /var/www/html/info.php................"


      # indicate content is being served from master node
      echo "<h1>Served from Master Node</h1>" | sudo tee -a /var/www/html/index.html

      echo "....................restarting apache2 webserver............................................"
      sudo systemctl restart apache2

      # Add cron job to monitor processes
      sudo touch /vagrant/cron_processes.txt
      echo "..........Adding cron job to monitor processes.........................."
      (sudo crontab -l 2>/dev/null; echo "@reboot ps aux >> /vagrant/cron_processes.txt") | sudo crontab -

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
    s.vm.provision "shell", inline: <<-SHELL
      echo "..........Provisioning the slave node......................."
     
      # update and upgrade packages
      sudo apt-get update || { echo "Failed to update APT repo before provisioning slave node"; exit 1; }
      sudo apt-get upgrade -y || { echo "Failed to upgrade packages before provisioning master node"; exit 1; } 


      # Ensure .ssh directory exists
      sudo mkdir -p -m 700 /home/vagrant/.ssh
      sudo chown -R vagrant:vagrant /home/vagrant/.ssh

      # Add master node altschool user public key to authorized_key file in the slave node
      echo ".............Adding id_rsa.pub key to the slave node......................."
      if ! sudo grep -q "$(cat /vagrant/id_rsa.pub)" /home/vagrant/.ssh/authorized_keys 2>/dev/null; then
        echo -e "\n" | sudo tee -a /home/vagrant/.ssh/authorized_keys
        sudo cat /vagrant/id_rsa.pub | sudo tee -a /home/vagrant/.ssh/authorized_keys
        sudo chmod 600 /home/vagrant/.ssh/authorized_keys
        sudo chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
      fi
       

      sudo sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin no/' "/etc/ssh/sshd_config"
      sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' "/etc/ssh/sshd_config"
      sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' "/etc/ssh/sshd_config"
      sudo systemctl restart ssh || { echo "Failed to restart ssh"; exit 1; }



      # Copying the content of /mnt/altschool/ directory from vagrant into /mnt/altschool/slave in the slave node
      echo "..........Creating a /mnt/altschool/slave directory in the slave node.............................."
      sudo mkdir -p -m 755 /mnt/altschool/slave
      sudo chown -R vagrant:vagrant /mnt/altschool/slave


      if [[ -f /vagrant/test_data.txt ]]; then
          echo "test_data.txt exist in /vagrant directory"
          echo "copying test_data.txt to /mnt/altschool/slave directory in the slave node"
          sudo cp /vagrant/test_data.txt   /mnt/altschool/slave/
      else
          echo "Could not copy test_data.txt into /mnt/altschol/slave directory"
      fi



      echo "...............Installing Apache, PHP, and MySQL........................."
      sudo apt-get update || { echo "Failed to update before installing LAMP stack in the slave node"; exit 1; }
      export DEBIAN_FRONTEND="noninteractive"

      echo "................Generating a random secure MySQL root password for the slave node..................."
      SQL_ROOT_PASSWORD="$(openssl rand -base64 12)" # Secure random password

      echo "........MySQL root password is: $SQL_ROOT_PASSWORD................................"

      # Preconfigure MySQL password setup BEFORE installation
      sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $SQL_ROOT_PASSWORD"
      sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $SQL_ROOT_PASSWORD"

      
      sudo apt-get install -y apache2 mysql-server php libapache2-mod-php php-mysql || { echo "Failed to install LAMP stack on the slave node"; exit 1; }


      echo "..........Enabling mod_rewrite for Apache................................"
      sudo a2enmod rewrite || true

      # Starting and enabling Apache
      sudo systemctl start apache2
      sudo systemctl enable apache2


      # Secure MySQL installation
      echo ".................Disabling MySQL remote root login...................."
      sudo sed -i "s/.*bind-address.*/bind-address = 127.0.0.1/" /etc/mysql/mysql.conf.d/mysqld.cnf

      sudo systemctl restart mysql || { echo "failed to restart mysql"; exit 1; }

      # Show databases
      mysql -uroot -p"$SQL_ROOT_PASSWORD" -e "SHOW DATABASES;" || true

      # Clean up package cache
      sudo apt-get clean || true


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

# SSH into the master node as the default vagrant user
vagrant ssh master <<-EOL
  echo "......Welcome to Master node VM..........."
    
  # Display the content of test_data.txt in the master node
  echo "Displaying the content of test_data.txt in the master node"
  sudo cat /mnt/altschool/test_data.txt || { echo "Failed to display the content of test_data.txt in master node"; exit 1; }

  # Switch to the altschool user
  sudo -u altschool -i <<-EOSU

    # Test SSH connection to the slave node from the master node as 'altschool' user to 'vagrant' user on slave node
    echo "......Testing SSH connection to the slave node from the master node as 'altschool' user..."
    if ssh -o BatchMode=yes -o "StrictHostKeyChecking=no" vagrant@192.168.33.17 "echo SSH connection successful"; then
        echo "SSH connection to the slave node successful."
        
        # SSH into the slave node from the master node as 'altschool' user to 'vagrant' user on slave node
        echo "Connecting to the slave node from the master node"
        ssh -o "StrictHostKeyChecking=no" vagrant@192.168.33.17 <<-EOSS
          echo "Welcome to $(whoami) node"
          echo "Displaying the content of test_data.txt in the slave node"
          sudo cat /mnt/altschool/test_data.txt || { echo "Failed to display the content of test_data.txt in the slave node"; exit 1; }
          exit
        EOSS

    else
        echo "Error: SSH connection to the slave node failed. Please check the SSH key exchange or network connectivity." >&2
        exit 1
    fi

  EOSU

EOL

echo ".................Script Execution Complete......................."
```


## [Log Files](Log-files)

### [deploy.log](#deploy.log)

### [deploy_err.log](deploy_err.log)


## [Screenshots](Screenshots)

### [Screenshot of ControlNode and ManagedNode1 on VB](Screenshot_of_ControlNode_and_ManagedNode1_on_VB)


## [Usage](Usage)

**The following steps detail how to run the `deploy.sh` script:**

1. Ensure that you have a stable internet connection and sufficient resources on your host machine to spin up multiple VMs.

2. Clone this project's [GitHub repository](https://github.com/ikennaozurumba/vagrant-lamp-loadbalancer.git) by running the command:
   ```
   git clone https://github.com/ikennaozurumba/vagrant-lamp-loadbalancer.git
   ```

3. Navigate to the project directory by running the command:
   ```
   cd vagrant-lamp-loadbalancer
   ```

4. Ensure the script is executable by running the command:
   ```
   chmod +x deploy.sh
   ```

5. Execute the script by running the command:
   ```
   bash deploy.sh
   ```

6. After the deployment, you can access the Nginx load balancer via the IP address `192.168.33.18`. It should forward requests to either the master or slave node.


**Troubleshooting**
1. If the VMs fail to start, ensure that you have sufficient resources.
2. Check the deploy.log and deploy_err.log files for detailed logs.
3. Ensure that the SSH keys are correctly copied between the master and slave nodes.


 
## [Contributions](Contributions)

To contribute to this project, follow these steps:

1. Fork the project's GitHub repository [Github_Repository](https://github.com/ikennaozurumba/vagrant-lamp-loadbalancer.git).

2. Create a branch for the feature or bug fix.

3. Make the changes and commit them to the branch.

4. Submit a pull request to the main repository for review and integration.

## [References](#References)
- [GitHub Repository for Vagrant](https://github.com/hashicorp/vagrant)
- [Vagrant Documentation](https://www.vagrantup.com/docs)
- [VirtualBox documentation]([https://github.com/laravel/laravel](https://www.virtualbox.org/wiki/VBoxInstallAndRun)

## License
This project is licensed under the MIT License. See the LICENSE file for more details.
