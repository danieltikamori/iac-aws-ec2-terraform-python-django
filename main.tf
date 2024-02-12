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
  region = "us-west-2"
}

resource "aws_instance" "app_server-1" {
  ami           = "ami-01e82af4e524a0aa3"
  instance_type = "t2.micro"
  key_name      = "the key name to used for ssh"

  user_data = file("bootstrap.sh")

  tags = {
    Name = "test-1"
  }
}
