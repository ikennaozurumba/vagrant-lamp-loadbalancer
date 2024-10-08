# vagrant-lamp-loadbalancer

## Project Task: Deployment of Vagrant Ubuntu Cluster with LAMP Stack

### Objective:
Develop a bash script to orchestrate the automated deployment 
of two Vagrant-based Ubuntu systems, 
designated as 'Master' and 'Slave', 
with an integrated LAMP stack on both systems.

### Specifications:

    1. Infrastructure Configuration:
        Deploy two Ubuntu systems:
            Master Node: This node should be capable of acting as a control system.
            Slave Node: This node will be managed by the Master node.

    2. User Management:
        On the Master node:
            Create a user named altschool.
            Grant altschool user root (superuser) privileges.

    3. Inter-node Communication:
        Enable SSH key-based authentication:
            The Master node (altschool user) should seamlessly SSH into the Slave node without requiring a password.

    4. Data Management and Transfer:
        On initiation:
            Copy the contents of /mnt/altschool directory from the Master node to /mnt/altschool/slave on the Slave node. This operation should be performed using the altschool user from the Master node.

    5. Process Monitoring:
        The Master node should display an overview of the Linux process management, showcasing currently running processes.

    6. LAMP Stack Deployment:
        Install a AMP (Apache, MySQL, PHP) stack on both nodes:
            Ensure Apache is running and set to start on boot.
            Secure the MySQL installation and initialize it with a default user and password.
            Validate PHP functionality with Apache.

### Deliverables:

    A bash script encapsulating the entire deployment process 
        adhering to the specifications mentioned above.
    Documentation accompanying the script, 
       elucidating the steps and procedures for execution.
    A test PHP page validating the LAMP setup on both nodes 
    A Load balancer using nginx to allow for traffic to the LAMP using the master 
       and the slave nodes.
