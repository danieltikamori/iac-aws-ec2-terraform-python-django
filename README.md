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

## Aplication

Git clone the repository of your project to the project directory. E.g.:

```bash
git clone https://github.com/guilhermeonrails/clientes-leo-api
```

Now put the application into a Docker image. Create a `Dockerfile` file in the folder of your cloned project.
Example:

`clientes-leo-api/Dockerfile`

Define the project components inside this Docker container. See the documentation:
[Docker samples documentation](https://docs.docker.com/samples/)

Python example:

```dockerfile
# syntax=docker/dockerfile:1.4

FROM --platform=$BUILDPLATFORM python:3.7-alpine AS builder
EXPOSE 8000
WORKDIR /app
COPY requirements.txt /app
RUN pip3 install -r requirements.txt --no-cache-dir
COPY . /app
ENTRYPOINT ["python3"]
CMD ["manage.py", "runserver", "0.0.0.0:8000"]

FROM builder as dev-envs
RUN <<EOF
apk update
apk add git
EOF

RUN <<EOF
addgroup -S docker
adduser -S --shell /bin/bash --ingroup docker vscode
EOF
# install Docker tools (cli, buildx, compose)
COPY --from=gloursdocker/docker / /
CMD ["manage.py", "runserver", "0.0.0.0:8000"]
```

Or the code in this project:

```dockerfile
# FROM --platform=$BUILDPLATFORM python:3.7-alpine AS builder
FROM  python:3
ENV PYTHONDONTWRITEBYTECODE=1
# Python don´t write bytecode as it is unnecessary for most projects using containarization.
ENV PYTHONUNBUFFERED=1
# Don´t use buffer as it is unnecessary for most projects using containarization.
WORKDIR /home/ubuntu/tcc/
# Work directory
COPY . /home/ubuntu/tcc/
# Copies everything to the work directory
RUN pip3 install -r requirements.txt --no-cache-dir
# Installs the libraries / required components
RUN sed -i "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \['*'\]/" setup/settings.py
# Allows to respond to any requests without having a specific domain name configured
RUN python3 manage.py migrate
# Database migration
RUN python manage.py loaddata clientes.json
# Load initial database data from json file
ENTRYPOINT python manage.py runserver 0.0.0.0:8000
# Run server on port 8000 of IP address 0.0.0.0
EXPOSE 8000
# Exposed the 8000 port
```

### Build the image

Open the terminal and at the application directory (`clientes-leo-api/`), run:

```bash
docker build . -t production:V1
```

You may change the image name to something more meaningful if you want. The `-f` flag can be used to specify another Dockerfile. The `-t` flag allows you to tag your image with an alias so that you can refer to. This command will generate an image with the tag `production:V1`. `V1` refers to the production Dockerfile version 1.

## Permissions on AWS

Apply always the least privilege principle, so give only what is necessary on demand.

As long as possible, use the "jsonencode" function to avoid `json` formatting errors.
Terraform's "jsonencode" function converts a Terraform expression result to valid JSON syntax.

### Creating AWS Roles through the Terraform

See the documentation: [Terraform AWS iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)

Create a file named `role.tf` at infra/ directory and insert the following code:

```terraform
resource "aws_iam_role" "beanstalk_ec2" {
  name = "beanstalk-ec2-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  # tags = {
  #   tag-key = "tag-value"
  # }
}
```

#### Building policies

Then see this documentation: [iam_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy).

In the same `role.tf` file, paste the following below the previous code:

```terraform
resource "aws_iam_role_policy" "beanstalk_ec2_policy" {
name = "beanstalk-ec2-policy"
role = aws_iam_role.beanstalk_ec2.id

# Terraform's "jsonencode" function converts a

# Terraform expression result to valid JSON syntax.

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
       Action = [
          "cloudwatch:PutMetricData", # Visualize metrics through CloudWatch
          "ds:CreateComputer", # Create computers
          "ds:DescribeDirectories", # Describe directories to be able to change some of their properties
          "ec2:DescribeInstanceStatus", # Describe instances status to check if they are running
          "logs:*", # Store logs
          "ssm:*", # Manage SSM parameters
          "ec2messages:*", # Receive messages from other Amazon EC2 instances - communication between instances to improve load distribution at the load balancer
          "ecr:GetAuthorizationToken", # Get authorization token to pull images from ECR
          "ecr:BatchCheckLayerAvailability", # Check availability of layers in ECR
          "ecr:GetDownloadUrlForLayer", # Get download URL for layers in ECR
          "ecr:GetRepositoryPolicy", # Get repository policy
          "ecr:DescribeRepositories", # Describe repositories
          "ecr:ListImages", # List images
          "ecr:DescribeImages", # Describe images
          "ecr:BatchGetImage", # Get images from ECR
          "s3:*", # Create, read, update, and delete objects in Amazon S3 buckets
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
```

Find the permissions at:

ECR:
https://docs.aws.amazon.com/AmazonECR/latest/APIReference/API_Operations.html

EC2:
https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_Operations.html

#### Building the IAM instance profile

See: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile

In the same `role.tf` file, paste the following at the end:

```terraform
resource "aws_iam_instance_profile" "beanstalk_ec2_profile" {
  name = "beanstalk-ec2-profile"
  role = aws_iam_role.beanstalk_ec2.name
  
}
```
