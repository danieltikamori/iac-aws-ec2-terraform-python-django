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

resource "aws_instance" "app_server-1" {
  ami           = "ami-01e82af4e524a0aa3"
  instance_type = var.instance_type
  key_name      = var.instance_SSHKey

  user_data = file("bootstrap.sh")

  tags = {
    Name = "Terraform Ansible Python"
  }
}

resource "aws_key_pair" "SSHKey" {
  key_name = var.instance_SSHKey
  public_key = file("${var.instance_SSHKey}.pub")
}

output "public_ip" {
  value = aws_instance.app_server-1.public_ip
}

output "public_dns" {
  value = aws_instance.app_server-1.public_dns
}