# Vagrant LAMP Load Balancer

This project sets up a local development environment with a LAMP stack (Linux, Apache, MySQL, PHP) and a load balancer using Vagrant, VirtualBox, and Nginx. The environment includes a master node, a slave node, and a load balancer that forwards requests to either the master or slave node.

## Project Overview

This setup creates a scalable and load-balanced web server environment. The architecture consists of:

- **Master Node**: Hosts a LAMP stack.
- **Slave Node**: A replica of the master node for load balancing purposes.
- **Load Balancer Node**: An Nginx load balancer that forwards incoming traffic to either the master or slave node based on availability and load.

The project uses `Vagrant` for VM management and `VirtualBox` as the hypervisor. The configuration is defined in a `Vagrantfile` that provisions the necessary VMs.

## Requirements

Before you start, ensure you have a UNIX-based operating system (e.g., Linux) installed and running on your local machine, as the deploy.sh script will only run in a UNIX environment. 
If you are running on a Windows machine, ensure that [WSL (Windows Subsystem for Linux)](https://docs.microsoft.com/en-us/windows/wsl/install) is installed to provide a Unix-like environment.

## Setup Instructions

Follow the steps below to get the environment running:

### 1. Clone the Repository

```bash
git clone https://github.com/ikennaozurumba/vagrant-lamp-loadbalancer.git
cd vagrant-lamp-loadbalancer
```

### 2. Run the Deployment Script

Ensure you have sufficient resources and an active internet connection, then execute the following commands:

```bash
chmod +x deploy.sh
bash deploy.sh
```

### 3. Access the Load Balancer

Once the deployment is complete, you can access the Nginx load balancer via the IP address:

```
http://192.168.33.18
```

The load balancer will distribute traffic to either the master or slave node.

## Script Details

The `deploy.sh` script automates the installation and configuration of:

- **Vagrant**: Manages virtual machines.
- **VirtualBox**: Acts as the hypervisor for the VMs.
- **Nginx**: Configured as a load balancer.
- **Apache/MySQL/PHP**: Installed on both master and slave nodes (LAMP stack).

The script handles the following tasks:

1. Installs Vagrant and VirtualBox (if not already installed).
2. Configures the master and slave nodes using the base box `ubuntu/focal64`.
3. Sets up the Nginx load balancer on the load balancer node.
4. Tests the connection between the master and slave nodes upon running `vagrant up`.

## Vagrantfile Configuration

The Vagrantfile is configured to provision three VMs:

1. **Master Node**: Runs a LAMP stack (`192.168.33.10`).
2. **Slave Node**: Runs a replica LAMP stack (`192.168.33.11`).
3. **Load Balancer Node**: Nginx acting as a reverse proxy load balancer (`192.168.33.18`).

Each VM is provisioned with `ubuntu/focal64` as the base box and specific resources (e.g., CPU and memory) tailored to their role.

## Troubleshooting

If you encounter issues, you can try the following:

- Ensure all dependencies (Vagrant, VirtualBox, etc.) are installed correctly.
- Run `vagrant up` manually if the script fails.
- Check the VMs’ status using `vagrant status`.
- Access individual VMs for troubleshooting via `vagrant ssh <vm_name>`.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributions

Contributions are welcome! Please open an issue or submit a pull request if you have suggestions or improvements.
