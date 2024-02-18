module "Homologation" {
  source = "../../infra"
  name = "homologation"
  description = "omologation-application"
  maxSize = 3
  machine = "t2.micro"
  environment = "homologation-environment"
}