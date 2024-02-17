module "aws-dev" {
  source = "../../infra"
  instance_type = "t2.micro"
  # instance_count = 1
  # instance_name = "dev-server"
  aws_region = "us-west-2"
  instance_SSHKey = "IaC-DEV"
  securityGroup = "Dev"
  minSize = 0  # For Dev and Staging/Test, it can be 0 as it must be offline sometimes.
  maxSize = 1
  # desiredCapacity = 0
  asGroupName = "Dev"
}

# output "dev_ip" {
#   value = module.aws-dev.public_ip
# }

# output "dev_dns" {
#   value = module.aws-dev.public_dns
# }