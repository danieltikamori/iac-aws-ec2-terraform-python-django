# IaC project - AWS, Terraform, Ansible to deploy a Django web application on EC2 instance

## Introduction

This project is an example of how to use Terraform, Ansible, and AWS to deploy a Django web application on an EC2 instance.

## Prerequisites

- Terraform
- Ansible
- AWS account

## Creating SSH keys and configuring the keys

### Creating SSH keys

Create at least 2 keys. The first will be for Development environment and the second for Production environment.

At the project directory, open the Terminal.
Run:
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

Note: Replace the “your_email@example.com” with your email address (this is a comment for your SSH key)

Whenever you enter the above command, it will ask you some questions like file name and location, and also a passphrase for your key. It’s recommended to use a passphrase for more security and access control.

The first key, type for example `./IaC-DEV`.
The second key, type for example `./IaC-PROD`.

### Make directories to organize the project

/infra
/env/Dev
/env/Prod

### Configuring the keys

#### Production environment

Move the `.pem` file to the `/env/Prod` directory.

#### Development environment

Move the `.pem` file to the `/env/Dev` directory.

## Terraform

### Deploying the infrastructure using Terraform

1. Create a new directory for the Terraform project: `mkdir django_ec2` and navigate into it: `cd django_ec2`.
2. Initialize Terraform: `terraform init`
3. Create a new Terraform configuration file: `touch main.tf`
4. Add the code to the main.tf file. You can use the provided example or modify it according to your requirements.
5. Run Terraform to create the infrastructure: `terraform apply`

### Destroying the infrastructure using Terraform

1. Run Terraform to destroy the infrastructure: `terraform destroy`

### Updating the infrastructure using Terraform

1. Run Terraform to update the infrastructure: `terraform apply`

### Get Terraform outputs

1. Run Terraform to get the outputs: `terraform output`

### Initializing the environment

Every environment with main.tf must be initialized before applied.

1. Initialize the environment. At the environment directory, run: `terraform init`
  
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

### Create Terraform files

#### main.tf

Inside `/infra` create `main.tf`, this file will be used as an entry point for Terraform.
Also create `variables.tf` and `outputs.tf`.
Inside `/env/Dev` create `main.tf`.
Inside `/env/Prod` create `main.tf`.

### Security groups

At `infra/variables.tf` file, add this variable:

```terraform
variable "securityGroup" {
  type = string
}
```

Create or go to the `infra/security_group.tf` file and add this resource and modify accordingly:

```terraform
resource "aws_security_group" "<desired name>" {
  name = var.securityGroup # <desired name>

  # description = ""
  # vpc_id = aws_vpc.main.id

  ingress { # Allow incoming traffic("listen")
    from_port = 0
    to_port = 0   # 0 means all ports
    protocol = "-1" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = [ "::/0" ]
  }
  egress { # Allow outgoing traffic("send")
    from_port = 0
    to_port = 0   # 0 means all ports
    protocol = "-1" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = [ "::/0" ]
  }
  tags = {
    Name = "<desired tag>"
  }
}
```

It is recommended to create several security groups(resource "aws_security_group") for each environment. Each environment requires proper ports and protocols
> Note that you need to replace `<desired name>` with a desired name for your security group.

- Also note that if you want to associate this security group with an IP range (for example, only allow access from certain IP addresses), you can use the `cidr_blocks` attribute.

- Also note that if you want to use an existing VPC instead of creating one in this module, you can use the `vpc_id` attribute.

Then in `infra/main.tf` file, add at the launch template:

```terraform
security_group_names = [var.securityGroup]
```

Finally, add inside the module aws-<environment> the following to applicable environments `env/<environment>/main.tf` files:

```terraform
module "aws-<environment>" {
......
......
securityGroup = "<environment>" # E.g.: Dev, Test, Production
}
```

### Autoscaling group

Use aws_launch_template to create autoscaling group instead of aws_instance.

```terraform
resource "aws_launch_template" "machine" {
  image_id      = "ami-01e82af4e524a0aa3"
  instance_type = var.instance_type
  key_name      = var.instance_SSHKey
  user_data = filebase64("ansible.sh") # Converts to base64 and adds to user_data field, otherwise AWS will not accept it.
  # user_data = base64encode(file("bootstrap.sh"))
  security_group_names = [var.securityGroup]
  # vpc_security_group_ids = [ aws_security_group.securityGroup.id ]
  tags = {
    Name = "Terraform Ansible Python"
  }
}
```

At `infra/main.tf` file, add resource "aws_autoscaling_group":

```terraform
resource "aws_autoscaling_group" "asGroup" {
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  name = var.asGroupName
  max_size = var.maxSize
  min_size = var.minSize
  # desired_capacity = var.desiredCapacity
  launch_template {
    id = aws_launch_template.machine.id
    version = "$Latest"

  }
  tag {
    key = "Name"
    value = var.asGroupName
    propagate_at_launch = true
  }
}
```

And at environment's `main.tf` files, add at module aws-<environment>:

```terraform
  minSize = 1 # Minimum number of instances for production must be at least 1, or it may be offline. For Dev and Staging/Test, it can be 0 as it must be offline sometimes.
  maxSize = 10
  # desiredCapacity = 2
  asGroupName = "<environment>"
```

### Load balancer

Add the following code to `infra/main.tf` file to set the load balancer:

```terraform
resource "aws_alb" "<loadBalancer-main>" {
  name = "loadBalancer-main"
  internal = false
  subnets = [aws_default_subnet.defaultSubnet_az1.id, aws_default_subnet.defaultSubnet_az2.id]
  count = var.production ? 1 : 0 # Ternary operator that verifies if production is true. If it is, it will create the load balancer. Otherwise, it will not.
  # security_groups = [aws_security_group.general_access.id]
  
}

resource "aws_alb_listener" "albListener" {
  load_balancer_arn = aws_alb.loadBalancer-main[0].arn
  port = 8000
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.albTargetGroup[0].arn # As we are usin the count variable, we need to specify the index of the target group and other resources related to the load balancer.
  }
  count = var.production ? 1 : 0 # Ternary operator that verifies if production is true. If it is, it will create the load balancer listener. Otherwise, it will not.
}

resource "aws_alb_target_group" "albTargetGroup" {
  name = "machinesTargetGroup"
  port = 8000
  protocol = "HTTP"
  vpc_id = aws_default_vpc.default.id
  count = var.production ? 1 : 0 # Ternary operator that verifies if production is true. If it is, it will create the target group. Otherwise, it will not.
}

resource "aws_default_vpc" "default" {

}

resource "aws_autoscaling_policy" "production-scaling" {
  name = "terraform-production-scaling"
  autoscaling_group_name = var.asGroupName
  policy_type = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
  count = var.production ? 1 : 0 # Ternary operator that verifies if production is true. If it is, it will create the autoscaling policy. Otherwise, it will not.
}
```

To define if the environment will have load balancer or not, at environments `main.tf` files, add inside the module:

```terraform
production = true # Or false if don´t want to use load balancer
```

### Defining the configuration for each environment using the ternary operator

In the code above, it is already configured.

For example at the launch template:

```terrform
user_data = var.production ? filebase64("ansible.sh") : "" # Ternary operator that verifies if production is true. Converts the file into a base64 encoded string to be used in the launch template.
```

Another example to define if the environment will have load balancer or not:

```terraform
resource "aws_autoscaling_group" "name" {
......
target_group_arns = var.production ? [aws_alb_target_group.albTargetGroup[0].arn] : [] # Ternary operator that verifies if production is true. If it is, it will add the target group to the autoscaling group. Otherwise, it will not.
  # As we are using the count parameter for the load balancer, we must specify the index of the resources related to the load balancer.
}
```

For the load balancer, it is necessary to create ternary operators across related resources and specify the index of the related resources where necessary.

## Ansible

Ansible is used for configuring and managing the deployed resources. The playbook (`playbook.yml`) is used to automate the deployment of the Django web application on the EC2 instance. 
You must have Python installed as it will be required by Ansible. You can check this with the command: `python --version`.

### Installing Ansible

To install Ansible, you can use the following command: `sudo apt-get install ansible` for Debian-based systems or `sudo yum install ansible` for Red Hat-based systems.
Ansible is already installed if you are running this in a Docker container (e.g., using Docker Compose).

### Running Ansible playbook

To run an Ansible playbook against your newly created EC2 instances you need to SSH into the instances and run the playbook.
Ansible is used for configuring and setting up the deployed resources. The playbook can be executed by running the following command in the directory containing the playbook (ansible/playbooks) or project directory:

For .pem file generated by AWS:

`ansible-playbook <path to>playbook.yml -u <username> --private-key <path to><private-key-filename>.pem -i <path to>hosts.yml`

For key generated with ssh-keygen (that file without extension):

`ansible-playbook <path to>playbook.yml -u <username> --key-file <path to><private-key-filename> -i <path to>hosts.yml`

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

The yaml format:
yaml is a human-readable data serialization language. It is often used for configuration files and in applications where data is being stored or transmitted.

yaml format is used for playbooks because it allows us to include comments within each task. This makes it easier to understand and maintain playbooks.

#### playbook.yml

Inside `/infra` create `playbook.yml`.
Inside `/env/Dev` create `playbook.yml`.
Inside `/env/Prod` create `playbook.yml`.

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
1. Install Django and Django Rest Framework:

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
1. Start the Django project:

    ```yaml
    - name: Starting the Project
      shell: '. /home/ec2-user/web/venv/bin/activate; django-admin startproject setup /home/ec2-user/web/'
      # ignore_errors: yes
    ```

    This task uses the `shell` module to execute a shell command that activates the virtual environment and then creates a new Django project named `setup` in the `/home/ec2-user/web/` directory.
&nbsp;
1. Change the hosts in the settings.py file:

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

##### Idempotence and Handlers

The `become` directive is used to make sure that all commands are run as the user who owns the web server process, which is typically "nobody". The `ignore_errors` directive is used to ignore any errors that may occur during the execution of the playbook.
Idempotent operations are actions that can be repeated without changing the result beyond the initial state.

In our case, we want to ensure that `django-admin` is run only once per instance.

To achieve this, we can use the `handlers` feature of Ansible. A handler is a piece of code that you can call from multiple places within your playbook. To achieve this, we use a special handler named "idempotency" which checks if the command has already been run and if not, it runs it.
To achieve this, we use a handler named "started" which checks if the directory `/home/ec2-user/web` exists and if not, it creates it.

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
2. Check the output of the last task that was executed (`tail /var/log/syslog`).
3. Look at the status page of the deployed app (`http://yourserverip:8000/status`).
4. Check the logs of the Django server (`tail -f /var/log/django.log`).
5. Check the logs of the Nginx server (`tail -f /var/log/nginx/error.log`).
6. If everything seems fine but the website does not work as expected, try restarting the server (`sudo service django restart`).
