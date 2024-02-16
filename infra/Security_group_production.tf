resource "aws_security_group" "production_env"{
  name = "production_env"
  description = "Security group for production environment"
  # vpc_id = aws_vpc.main.id


# HTTP protocol
  ingress { # Allow incoming traffic("listen")
    from_port = 80
    to_port = 80   # 0 means all ports
    protocol = "HTTP" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = [ "::/0" ]
  }
  egress { # Allow outgoing traffic("send")
    from_port = 80
    to_port = 80   # 0 means all ports
    protocol = "-1" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = [ "::/0" ]
  }

  #HTTPS protocol
  ingress { # Allow incoming traffic("listen")
    from_port = 443
    to_port = 443   # 0 means all ports
    protocol = "HTTPS" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = [ "::/0" ]
  }
  egress { # Allow outgoing traffic("send")
    from_port = 443
    to_port = 443   # 0 means all ports
    protocol = "-1" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = [ "::/0" ]
  }

  tags = {
    Name = "production_env"
  }

}