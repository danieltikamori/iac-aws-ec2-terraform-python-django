module "Production" {
  source = "../../infra"
  name = "production"
  description = "production-application"
  maxSize = 5
  machine = "t2.micro"
  environment = "production-environment"
}