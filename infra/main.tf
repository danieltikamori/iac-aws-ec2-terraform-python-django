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
  image_id = "ami-008fe2fc65df48dac"
  # image_id      = "ami-01e82af4e524a0aa3" # Amazon Linux 2023
  instance_type = var.instance_type
  key_name      = var.instance_SSHKey
  user_data = var.production ? filebase64("ansible.sh") : "" # Ternary operator that verifies if production is true. Converts the file into a base64 encoded string to be used in the launch template. Otherwise AWS will not be able to use it.
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
  target_group_arns = var.production ? [aws_alb_target_group.albTargetGroup[0].arn] : [] # Ternary operator that verifies if production is true. If it is, it will add the target group to the autoscaling group. Otherwise, it will not.
  # As we are using the count parameter for the load balancer, we must specify the index of the resources related to the load balancer.

  tag {
    key = "Name"
    value = var.asGroupName
    propagate_at_launch = true
  }
}

resource "aws_default_subnet" "defaultSubnet_az1" {
  availability_zone = "${var.aws_region}a"
}

resource "aws_default_subnet" "defaultSubnet_az2" {
  availability_zone = "${var.aws_region}b"
}

resource "aws_alb" "loadBalancer-main" {
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