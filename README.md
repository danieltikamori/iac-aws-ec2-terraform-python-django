# IaC project - AWS, Terraform, Ansible to deploy a Django web application on EC2 instance

## Introduction

This project is an example of how to use Terraform, Ansible, and AWS to deploy a Django web application on an EC2 instance.

## Prerequisites

-   Terraform
-   Ansible
-   AWS account
   
## Terraform

### Deploying the infrastructure using Terraform

1.  Create a new directory for the Terraform project: `mkdir django_ec2` and navigate into it: `cd django_ec2`.
2.  Initialize Terraform: `terraform init`
3.  Create a new Terraform configuration file: `touch main.tf`
4.  Add the code to the main.tf file. You can use the provided example or modify it according to your requirements.
5.  Run Terraform to create the infrastructure: `terraform apply`
   
### Destroying the infrastructure using Terraform

1.  Run Terraform to destroy the infrastructure: `terraform destroy`
  
### Terraform files explanation

#### main.tf

This code is written in Terraform, a popular Infrastructure as Code (Ia) tool used for provisioning and managing cloud resources. The code defines an AWS infrastructure setup with a single EC2 instance. Here's a breakdown of the code:

1. `terraform {`: This block is used to configure Terraform settings.
    - `required_providers`: This section specifies the required providers and their versions. Here, it indicates that the AWS provider (by HashiCorp) with a version greater than or equal to 4.16.0 is needed.

- `required_version`: This line specifies the minimum required version of Terraform to be 1..0 or higher.

2. `provider "aws" { }`: This block configures the AWS provider.
    - `profile`: This sets the AWS credentials profile to use from the default AWS CLI configuration file (~/.aws/credentials).
    - `region`: This attribute sets the default region for AWS operations.
3. `resource "aws_instance" "app_server-1" { ... }`: This block defines an AWS EC2 instance resource.
    - `ami`: This attribute sets the Amazon Machine Image (AMI) ID for the instance. Here, it uses an Ubuntu AMI (ami-01e82af4e524a0aa3).
    - `instance_type`: This attribute sets the instance type (size). Here, it uses a t2.micro instance.
    - `key_name`: This attribute sets the name of the key pair to associate with the instance for SSH access.
    - `user_data`: This attribute specifies a script to execute on the instance at launch. Here, it uses a file named "bootstrap.sh".
    - `tags`: This block sets metadata tags for the instance. Here, it sets a tag named "Name" with the value "test-1".

In summary, this Terraform code creates an AWS EC2 instance with a specific AMI, instance type, SSH key pair, and user data script. The instance is tagged with a name for easy identification.

#### bootstrap.sh

This is a bash script for a system that uses the yum package manager, such as Amazon Linux or CentOS. Here is an explanation of what each line does:

1. `#!/bin/bash`: This is called a shebang and tells the system that this script should be executed using the bash shell interpreter.
2. `yum update -y`: This command updates all the packages on the system to their latest versions. The `-y` flag automatically confirms any prompts that may appear during the update process.
3. `yum install httpd.x86_64 -y`: This command installs the httpd package, which is the Apache HTTP Server. The `.x86_64` specifies the architecture of the package, and the `-y` flag automatically confirms any prompts that may appear during the installation process.
4. `systemctl start httpd`: This command starts the Apache HTTP Server.
5. `systemctl enable httpd`: This command sets the Apache HTTP Server to start automatically when the system boots up.

In summary, this script updates the system, installs the Apache HTTP Server, starts the server, and sets it to start automatically on boot.

   
## Ansible

Ansible is used for configuring and managing the deployed resources. The playbook (`playbook.yml`) is used to automate the deployment of the Django web application on the EC2 instance. 
You must have Python installed as it will be required by Ansible. You can check this with the command: `python --version`.

### Installing Ansible

To install Ansible, you can use the following command: `sudo apt-get install ansible` for Debian-based systems or `sudo yum install ansible` for Red Hat-based systems.
Ansible is already installed if you are running this in a Docker container (e.g., using Docker Compose).

### Running Ansible playbook

To run an Ansible playbook against your newly created EC2 instances you need to SSH into the instances and run the playbook.
Ansible is used for configuring and setting up the deployed resources. The playbook can be executed by running the following command in the directory containing the playbook (ansible/playbooks):

`ansible-playbook playbook.yml -u <username> --private-key <private-key-filename>.pem -i hosts.yml`

### Ansible playbook structure and purpose

The playbook consists of two parts:

1. **Installation**: This part sets up all necessary packages for Python and Django on the remote host.
2. **Deployment**: This part deploys the Django web application on the remote host.

#### Variables

Variables are defined in the `group_vars/all.yml` file. You can modify these variables to suit your needs.

#### Installation tasks

The installation tasks are defined in the `roles/install/tasks/main.yml` file.

#### Deployment tasks

The deployment tasks are defined in the `roles/deploy/tasks/main.yml` file.
This includes creating directories, copying files, installing dependencies, and starting the Django server.

- Note that the `restart_server` task uses the `service` module from Ansible's core package. If you prefer not to use it, you could write a custom script to restart the server.
You can find more information about Ansible roles [here](http://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html).
You may want to customize some of these tasks according to your specific requirements. For example, if you don't need SSL support, you can remove the "Enable HTTPS" task from the playbook.
- Note that the `restart_server.sh` script is used to gracefully restart the Django server. It sends a SIGUSR1 signal to the server process, which triggers a safe shutdown.
Note that the `restart_server` task uses the `service` module from the Ansible core package. If you encounter issues with restarting the server, consider using the `systemd` module instead.

- Note that the `restart=yes` flag tells Ansible to restart the server whenever it makes changes to the configuration files.

### Ansible Files explanation

#### playbook.yml

This Ansible playbook is used to automate the deployment of a Django web application on an EC2 instance. Here's a step-by-step explanation of the tasks in the playbook:

1. Install python3 and virtualenv:

    ```yaml
   - name: Installing python3, virtualenv
      yum:
        pkg:
        - python3
        - virtualenv
        update_cache: yes
      become: yes
    ```

    This task uses the `yum` module to install the `python3` and `virtualenv` packages on the remote host. The `become: yes` line is used to elevate the user's privileges to root.
&nbsp;
2. Install Django and Django Rest Framework:

    ```yaml
    - name: Installing dependencies with pip (Django and Django Rest)
      pip:
        virtualenv: /home/ec2-user/web/venv
        name:
        - django
        - djangorestframework
    ```

    This task uses the `pip` module to install the `django` and `djangorestframework` packages in the virtual environment located at `/home/ec2-user/web/venv`.
&nbsp;
3. Start the Django project:

    ```yaml
    - name: Starting the Project
      shell: '. /home/ec2-user/web/venv/bin/activate; django-admin startproject setup /home/ec2-user/web/'
      # ignore_errors: yes
    ```

    This task uses the `shell` module to execute a shell command that activates the virtual environment and then creates a new Django project named `setup` in the `/home/ec2-user/web/` directory.
&nbsp;
4. Change the hosts in the settings.py file:

    ```yaml
    - name: Changing the hosts in the settings.py file
      lineinfile:
        path: /home/ec2-user/web/setup/settings.py
        regexp: 'ALLOWED_HOSTS'
        line: 'ALLOWED_HOSTS = ["*"]'
        backrefs: yes
    ```

    This task uses the `lineinfile` module to replace the line containing `ALLOWED_HOSTS` in the `settings.py` file of the Django project with `ALLOWED_HOSTS = ["*"]`. This allows the Django application to accept requests from any host.

Please note that the `become: yes` line is used in each task to elevate the user's privileges to root. This is necessary because the tasks involve installing packages and modifying files, which typically require root privileges.

#### hosts.yml

The code in the `hosts.yml` file is a YAML configuration file for Ansible. Ansible is an open-source automation tool that can be used to automate tasks such as configuration management, application deployment, and infrastructure orchestration.

The `[terraform-ansible]` lines are comments in the YAML file. They are used to provide explanations or labels for the following lines. In this case, the comments indicate that the user should write the IP address of the instance/server they want to manage.

The actual configuration in the `hosts.yml` file should look something like this:

```yaml

[terraform-ansible]
# write instance/server IP here 
192.168.1.10`
```
In this example, `192.168.1.10` is the IP address of the instance/server that the user wants to manage using Terraform-Ansible.

The `hosts.yml` file should be placed in the `inventory` directory of the Ansible project. The `inventory` directory is where Ansible looks for host information.

When Ansible runs, it will use the IP address specified in the `hosts.yml` file to connect to the instance/server and execute the tasks defined in the Ansible playbook.

It is important to note that the IP address should be replaced with the actual IP address of the instance/server that the user wants to manage. The IP address should be a valid IPv4 or IPv6 address.

The `hosts.yml` file is not a part of Terraform configuration. It is used by Ansible to manage the instances/servers. The actual Terraform configuration should be placed in a `.tf` file, such as `main.tf`. The `main.tf` file contains the necessary information for Terraform to create and manage the infrastructure.

In summary, the `hosts.yml` file is used by Ansible to manage the instances/servers specified in the file. The actual Terraform configuration should be placed in a `.tf` file.

- Note that you need to replace `192.168.1.10`

## Troubleshooting

If you encounter any issues with the deployment, you can use the following steps to troubleshoot:

1. Check the output of the Ansible run. If there are errors or warnings, they will be displayed in the output.
2.  Check the output of the last task that was executed (`tail /var/log/syslog`).
3.  Look at the status page of the deployed app (`http://yourserverip:8000/status`).
4.  Check the logs of the Django server (`tail -f /var/log/django.log`).
5.  Check the logs of the Nginx server (`tail -f /var/log/nginx/error.log`).
6.  If everything seems fine but the website does not work as expected, try restarting the server (`sudo service django restart`).
