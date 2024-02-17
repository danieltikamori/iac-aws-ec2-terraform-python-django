resource "aws_security_group" "general_access" {
  name = "General access"
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
    Name = "general_access"
  }
}

resource "aws_security_group" "Production" {
  name = "Production"
  description = "For production enviroment traffic"
  # vpc_id = aws_vpc.main.id

  ingress { # Allow incoming traffic("listen")
    from_port = 80
    to_port = 80  # 0 means all ports
    protocol = "tcp" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = [ "::/0" ]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol = "tcp"

    # Allow access from anywhere (0.0.0.0/0) for HTTPS
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8000
    to_port   = 8000
    protocol = "tcp"

    # You can restrict access to specific CIDR blocks or security groups here
    cidr_blocks = ["0.0.0.0/0"]
    # security_groups = ["sg-0123456789abcdef"]
  }

  egress { # Allow outgoing traffic("send")
    from_port = 0
    to_port = 0  # 0 means all ports
    protocol = "-1" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = [ "::/0" ]
  }
  tags = {
    Name = "production_access"
  }
}