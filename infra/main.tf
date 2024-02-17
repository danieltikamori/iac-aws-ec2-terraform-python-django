terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  profile = "default"
  region = var.aws_region
}

resource "aws_launch_template" "machine" {
  image_id      = "ami-01e82af4e524a0aa3"
  instance_type = var.instance_type
  key_name      = var.instance_SSHKey
  user_data = filebase64("ansible.sh") # Converts the file into a base64 encoded string to be used in the launch template. Otherwise AWS will not be able to use it.
  # user_data = base64encode(file("bootstrap.sh"))
  security_group_names = [var.securityGroup]
  # vpc_security_group_ids = [ aws_security_group.securityGroup.id ]
  tags = {
    Name = "Terraform Ansible Python"
  }
}

# resource "aws_instance" "app-server-1" {
#   ami      = "ami-01e82af4e524a0aa3"
#   instance_type = var.instance_type
#   key_name      = var.instance_SSHKey
#   user_data = file("bootstrap.sh")
#   security_groups = [ var.securityGroup ]

#   tags = {
#     Name = "Terraform Ansible Python"
#   }
# }

resource "aws_key_pair" "SSHKey" {
  key_name = var.instance_SSHKey
  public_key = file(".keys/${var.instance_SSHKey}.pub")
}

# output "public_ip" {
#   value = aws_instance.app_server-1.public_ip
# }

# output "public_dns" {
#   value = aws_instance.app_server-1.public_dns
# }

resource "aws_autoscaling_group" "asGroup" {
  availability_zones = ["${var.aws_region}a"]
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