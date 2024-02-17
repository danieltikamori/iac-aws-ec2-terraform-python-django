terraform {
  backend "s3" {
    bucket = "terraform-state-alura-iac"
    key    = "Prod/terraform.tfstate"
    region = "us-west-2"
  }
}
