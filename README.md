# IaC AWS using Docker, Elastic Beanstalk, Terraform, Ansible and Django framework

## Project configurations

### Create directories to organize the project

infra/
env/homolog/
env/Prod/

### Set the provider

Create a `provider.tf` file at infra/ directory and paste the following code:

```terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-west-2"
}
```

This configuration sets up the AWS provider with the specific region we want our resources in.

### Set the S3 bucket to store and use the terraform states

Manually create a S3 bucket at AWS Console, or through CLI. Choose a unique name for the bucket.
Open [S3 backends Terraform](https://developer.hashicorp.com/terraform/language/settings/backends/s3), then copy the code.

Then create a backend.tf file in the `env/Prod` directory and paste the code or use this model:

```terraform
terraform {
  backend "s3" {
    bucket = "mybucket"
    key    = "Prod/terraform.tfstate"
    region = "us-east-1"
  }
}
```

Modify as necessary.

## Container with Docker

### Repository

Create an AWS ECR repository using Terraform:
Open the Terraform documentation: [AWS ECR Terraform](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository)

Copy the code at the documentation and create an `ecr.tf` file in infra/ directory, then paste the code or use this model:

```terraform
resource "aws_ecr_repository" "repository" {
  name                 = var.name # Recommended to use variable, `var.name` instead of hardcoded value.
  image_tag_mutability = "MUTABLE" # optional, default is MUTABLE.

  image_scanning_configuration { # optional, by default, image scanning must be manually triggered.
    scan_on_push = true
  }
}
```

Create the `variable.tf` file at infra/ directory (if not already created) and add the following lines:

```terraform
variable "name" {
  type = string
}
```

It will set the variable "name".

Now if we run Terraform, we can see that it creates the ECR repo on the AWS console to put our Docker images.

