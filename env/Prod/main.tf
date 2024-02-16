module "aws-prod" {
  source = "../../infra"
  instance_type = "t2.micro" # Obviously, for production it is recommended to use a proper instance type
  # instance_count = 1
  # instance_name = "dev-server"
  aws_region = "us-west-2"
  instance_SSHKey = "IaC-PROD"
  securityGroup = "Production"
  
}

output "prod_ip" {
  value = module.aws-prod.public_ip
}

output "prod_dns" {
  value = module.aws-prod.public_dns
}