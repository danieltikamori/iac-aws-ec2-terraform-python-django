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
  region  = "us-west-2"
}

resource "aws_instance" "app_server" {
  ami           = "ami-01e82af4e524a0aa3"
  instance_type = "t2.micro"
  key_name = "first-tkmr"

  tags = {
    Name = "tkmr-server-1"
  }
}
