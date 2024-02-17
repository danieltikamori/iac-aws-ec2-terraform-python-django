variable "aws_region" {
  type = string
  # default = "us-west-2"
}
variable "instance_SSHKey" {
  type = string
}
variable "instance_type" {
  type = string
  # default = "t3.micro"
}
# variable "instance_ami" {
#   type = string
#   # default = "ami-008fe2fc65df48dac"
# }
# variable "instance_count" {
#   type = int
#   # default = 1
# }
variable "minSize" {
  type = number
}
variable "maxSize" {
  type = number
}
# variable "desiredCapacity" {
#   type = number
# }
# variable "instance_user" {
#   type = string
#   # default = "ec2-user"
# }

# variable "instance_name" {
#   type = string
#   # default = "my-ec2-instance"
# }
# variable "instance_tags" {
#   type = map(string)
#   # default = {
#   #   Name = "my-ec2-instance"
#   # }
# }
# variable "instance_key" {
#   type = string
#   # default = "my-ec2-key"
# }
variable "securityGroup" {
  type = string
  # default = "my-ec2-sg"
}
# variable "instance_subnet" {
#   type = string
#   # default = "my-ec2-subnet"
# }
# variable "instance_vpc" {
#   type = string
#   # default = "my-ec2-vpc"
# }
# variable "instance_iam" {
#   type = string
#   # default = "my-ec2-iam"
# }
# variable "instance_ebs" {
#   type = string
#   # default = "my-ec2-ebs"
# }
# variable "instance_ebs_type" {
#   type = string
#   # default = "gp2"
# }
# variable "instance_ebs_size" {
#   type = number
#   # default = 8
# }
# variable "instance_ebs_iops" {
#   type = number
#   # default = 100
# }
# variable "instance_ebs_encrypted" {
#   type = bool
#   # default = true
# }
# variable "instance_ebs_kms_key_id" {
#   type = string
#   # default = "alias/aws/ebs"
# }
# variable "instance_ebs_delete_on_termination" {
#   type = bool
#   # default = true
# }
# variable "instance_ebs_throughput" {
#   type = number
#   # default = 128
# }
# variable "instance_ebs_snapshot_id" {
#   type = string
#   # default = "snap-0b9b9e7b9b9b9b9b"
# }

variable "asGroupName" {
  type = string
}