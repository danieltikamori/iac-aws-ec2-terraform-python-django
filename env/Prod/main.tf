module "aws-dev" {
  source = "../../infra"
  instance_type = "t3.micro"
  # instance_count = 1
  # instance_name = "dev-server"
  aws_region = "us-west-2"
  instance_SSHKey = "IaC-DEV"
}

output "prod_ip" {
  value = module.aws-dev.public_ip
}

output "prod_dns" {
  value = module.aws-dev.public_dns
}