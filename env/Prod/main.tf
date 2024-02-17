module "aws-prod" {
  source = "../../infra"
  instance_type = "t2.micro" # Obviously, for production it is recommended to use a proper instance type
  # instance_count = 1
  # instance_name = "dev-server"
  aws_region = "us-west-2"
  instance_SSHKey = "IaC-PROD"
  securityGroup = "Production"

  minSize = 1 # Minimum number of instances for production must be at least 1, or it may be offline. For Dev and Staging/Test, it can be 0 as it must be offline sometimes.
  maxSize = 10
  # desiredCapacity = 2
  asGroupName = "Prod"
}

# output "prod_ip" {
#   value = module.aws-prod.public_ip
# }

# output "prod_dns" {
#   value = module.aws-prod.public_dns
# }