resource "aws_security_group" "general_access" {
  name = "var.securityGroup"
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