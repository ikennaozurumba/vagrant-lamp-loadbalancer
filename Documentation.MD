# Project Documentation

## Table of Contents

1. [Introduction](#Introduction)
2. [Project Overview](#Project-Overview)
   - [Objective](#Objective)
   - [Prerequisites](#Prerequisites)
3. [Project Structure](#Project Structure)
Getting Started
Installation
Setup
Running the Deployment
Project Components
Vagrantfile Configuration
Master Node Setup
Slave Node Setup
Load Balancer Setup
Testing and Validation
Troubleshooting
License
Prerequisites


# LAMP Stack Deployment with Reverse Proxy Load Balancer
This project automates the deployment of a LAMP (Linux, Apache, MySQL, PHP) stack across a master and slave node using Vagrant and VirtualBox. Additionally, it configures an Nginx reverse proxy load balancer to distribute traffic between the two nodes.
Before starting this deployment, ensure you have the following installed on your local machine:

VirtualBox
Vagrant
Project Structure
bash
Copy code
├── Vagrantfile
├── deploy.sh
└── README.md
Vagrantfile: Contains the configuration for the master, slave, and load balancer nodes.
deploy.sh: Bash script to automate the deployment process.
README.md: Documentation for the project.
Getting Started
Installation
Clone the Repository

bash
Copy code
git clone https://github.com/your-username/your-repo-name.git
cd your-repo-name
Ensure Prerequisites are Installed

Install VirtualBox
Install Vagrant
Setup
Ensure that you have proper internet connectivity and sufficient resources on your host machine to spin up multiple VMs.

Running the Deployment
To start the deployment, simply run the deploy.sh script:

bash
Copy code
./deploy.sh
This script will:

Check and install necessary dependencies (VirtualBox, Vagrant).
Create and configure the master, slave, and load balancer VMs.
Deploy and configure the LAMP stack on the master and slave nodes.
Set up the Nginx load balancer to distribute traffic between the nodes.
Project Components
Vagrantfile Configuration
The Vagrantfile is configured to spin up three virtual machines:

Load Balancer Node: Runs Nginx and forwards traffic to the master and slave nodes.
Master Node: Hosts a LAMP stack and serves as the primary server.
Slave Node: Hosts a LAMP stack and acts as a secondary server.
Master Node Setup
A new user altschool is created with SSH key-based authentication.
Apache, MySQL, and PHP are installed.
MySQL is secured, and Apache is configured to serve content from the master node.
Slave Node Setup
Apache, MySQL, and PHP are installed similarly to the master node.
SSH keys are configured to allow altschool user from the master node to access the slave node.
Load Balancer Setup
Nginx is installed and configured as a reverse proxy to distribute incoming traffic to the master and setup nodes.
Testing and Validation
Access the Load Balancer

After the deployment, you can access the Nginx load balancer via the IP 192.168.33.18. It should forward requests to either the master or slave node.

SSH Verification

SSH into the master node:

bash
Copy code
vagrant ssh master
Then, SSH into the slave node from the master node as the altschool user:

bash
Copy code
sudo -u altschool ssh vagrant@192.168.33.17
Verify LAMP Stack

Access http://192.168.33.16/info.php and http://192.168.33.17/info.php to verify the PHP installation on the master and slave nodes.

Troubleshooting
If the VMs fail to start, ensure that you have sufficient resources and that VirtualBox is properly configured.
Check the deploy.log and deploy_err.log files for detailed logs.
Ensure that the SSH keys are correctly copied between the master and slave nodes.
License
This project is licensed under the MIT License. See the LICENSE file for more details.

