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
 # user_data = <<-EOF
 #             #!/bin/bash
 #             cd /home/ec2-user
 #             echo "<h1>Hello, World<h1>" > index.html
 #             nohup busybox httpd -f -p 8080 &
 #             EOF
  tags = {
    Name = "tkmr-server-1"
  }
}
