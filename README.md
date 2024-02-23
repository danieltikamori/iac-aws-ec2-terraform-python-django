# IaC AWS using Docker, Elastic Beanstalk, Terraform, Python and Django framework

## Project configurations

### Create directories to organize the project

`infra/`

```bash
mkdir infra/
```

`env/homolog/`

```bash
mkdir env/homolog/
```

`env/Prod/`

```bash
mkdir env/Prod/
```

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
    region = "us-west-2"
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

## Application

Ideally, we should separate application versions for each environment, test and homolog in one environment and only push approved code to the production environment.

Git clone the repository of your project to the project directory. E.g.:

```bash
git clone https://github.com/guilhermeonrails/clientes-leo-api
```

**NOTE: the repository above is just for learning/testing purposes. You should replace this URL with your own application's repository.**

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

For homologation environment:

```bash
docker build . -t homologation:V1 # or v1
```

For production environment:

```bash
docker build . -t production:V1 # or v1
```

You may change the image name to something more meaningful if you want. The `-f` flag can be used to specify another Dockerfile. The `-t` flag allows you to tag your image with an alias so that you can refer to it. This command will generate an image with the tag `production:V1`. `V1` refers to the production Dockerfile version 1.

## Permissions on AWS

Apply always the least privilege principle, so give only what is necessary on demand.

As long as possible, use the "jsonencode" function to avoid `json` formatting errors.
Terraform's "jsonencode" function converts a Terraform expression result to valid JSON syntax.

### Creating AWS Roles through the Terraform

See the documentation: [Terraform AWS iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)

Create a file named `role.tf` at infra/ directory and insert the following code:

```terraform
resource "aws_iam_role" "beanstalk_ec2" {
  name = "beanstalk-ec2-role-${var.name}"

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

In the same `role.tf` file, paste below the previous code:

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
  name = "beanstalk-ec2-profile-${var.name}"
  role = aws_iam_role.beanstalk_ec2.name
}
```

### Create the Beanstalk application

See: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elastic_beanstalk_application

At infra/ directory, create the `beanstalk.tf` file and paste this code:

```terraform
resource "aws_elastic_beanstalk_application" "beanstalk_application" {
  name        = var.name
  description = var.description
}
```

At `infra/variables.tf` file, add the `description` variable:

```terraform
variable "description" {
  type = string
}
```

#### Create the elastic beanstalk environment

See: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elastic_beanstalk_environment

In the `infra/beanstalk.tf` file, add the following block of code after the `aws_elastic_beanstalk_application` resource:

```terraform
resource "aws_elastic_beanstalk_application" "beanstalk_application" {
  name        = var.name
  description = var.description
}

resource "aws_elastic_beanstalk_environment" "beanstalk_environment" {
  name                = var.environment
  application         = aws_elastic_beanstalk_application.beanstalk_application.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.2.1 running Docker" # see: https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/concepts.platforms.html#concepts.platforms.list In our case, use Docker: https://docs.aws.amazon.com/elasticbeanstalk/latest/platforms/platforms-supported.html#platforms-supported.docker Copy the description and paste at solution_stack_name
}
```

At `infra/variables.tf` file, add the `environment` variable:

```terraform
variable "environment" {
  type = string
}
```

#### Improving the environment

See: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elastic_beanstalk_environment#option-settings

In the `infra/beanstalk.tf` file, inside the `resource "aws_elastic_beanstalk_environment"` block, insert:

```terraform
  setting { # Set the instance type
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.machine
  }

    setting { # Set the autoscaling max number of instances
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = var.maxSize
  }
    setting { # Set the profile to be used
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.beanstalk_ec2_profile.name
  }
```

For this project, the code above is fine. Set for your project using the documentation: https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/command-options.html

Create the `machine` and `maxSize` variables at `infra/variables.tf` file:

```terraform
variable "machine" {
  type = string
}

variable "maxSize" {
  type = number
}
```

### Production and Homologation

Create a new file at `env/Prod`, you may name it as you wish but must have `.tf` extension (e.g., `env/Prod/main.tf`). Inside this file add:

```terraform
module "Production" {
  source = "../../infra" # To return the infra/ directory
  name = "production"
  description = "production-application"
  maxSize = 5
  machine = "t2.micro"
  environment = "production-environment"
}
```

**It is important to keep some attributes in lowercase to avoid incompatibilities at ECR repository.**
For example `name`, `description` and `environment`.

Then at the `Prod` directory, copy `backend.tf` and `main.tf` files and paste them into the `env/homolog` folder. After that, you can use this module in a similar way as above but changing the `Production` into `Homologation`:

`backend.tf` file:

```terraform
terraform {
  backend "s3" {
    bucket = "terraform-state-alura-iac"
    key    = "homolog/terraform.tfstate"
    region = "us-west-2"
  }
}
```

`main.tf` file:

```terraform
module "Homologation" {
  source = "../../infra"
  name = "homologation"
  description = "homologation-application"
  maxSize = 3
  machine = "t2.micro"
  environment = "homologation-environment"
}
```

## Deploying

#### Terraform initalization

Open the Terminal, go to `env/Prod/` directory and run `terraform init` to initialize the module and the Terraform. Do the same to other environments like `env/homolog`.

Then run `terraform apply` and accept typing `yes` to configure the infrastructure described by your configuration files, and then you can access it using SSH.

#### Upload (push) Docker image to ECR repository

See: https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html

##### 1. Authenticate

First adjust and then run the following command line arguments:

```bash
aws ecr get-login-password --region region | docker login --username AWS --password-stdin aws_account_id.dkr.ecr.region.amazonaws.com
```

Replace `region`, `aws_account_id` with your only numbers AWS account ID and the next `region`. E.g.

```bash
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 646456456452.dkr.ecr.us-west-2.amazonaws.com
```

###### Possible errors:

**Error:**

```bash
aws permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Post "http://%2Fvar%2Frun%2Fdocker.sock/v1.24/auth": dial unix /var/run/docker.sock: connect: permission denied
```

**Solution:**

If you want to run docker as non-root user then you need to add it to the docker group.

Create the docker group if it does not exist
$ sudo groupadd docker
Add your user to the docker group.
$ sudo usermod -aG docker $USER
Log in to the new docker group (to avoid having to log out / log in again; but if not enough, try to reboot):
$ newgrp docker
Check if docker can be run without root
$ docker run hello-world
$ sudo chmod 666 /var/run/docker.sock
Reboot if still got error

$ reboot

Warning

The docker group grants privileges equivalent to the root user. For details on how this impacts security in your system, see Docker Daemon Attack Surface.

Taken from the docker official documentation: manage-docker-as-a-non-root-user

**Error:**

```bash
Error saving credentials: error storing credentials - err: docker-credential-desktop resolves to executable in current directory (./docker-credential-desktop), out: ``
```

**Solution:**

In the file, `~/.docker/config.json`, change `credsStore` to `credStore` (note the missing s).

Explanation

The error seems to be introduced when moving from 'docker' to 'Docker Desktop', and vice-versa. In fact, Docker Desktop uses an entry credsStore, while Docker installed from apt uses credStore.

Extra

This solution also seems to work for the following, similar error:

Error saving credentials: error storing credentials - err: exec: "docker-credential-desktop":
executable file not found in $PATH, out: ``
which may occur when pulling docker images from a repository.

##### 2. Run docker images and push them to the registry

To see the list of the Docker images available on your system, you can use the following command:

```bash
docker images # or docker image ls
```

Copy the IMAGE ID corresponding to the Docker image you want to pull and then proceed with the next steps below.

Then adjust and run the following command accordingly with the IMAGE ID of the desired image, AWS account ID, region and repository:tag:

```bash
docker tag <IMAGE ID> <aws_account_id>.dkr.ecr.<us-west-2>.amazonaws.com/<my-repository:tag>
```

Example:

```bash
docker tag 5af3818676dc 646456456452.dkr.ecr.us-west-2.amazonaws.com/homologation:V1 # v1
```

```bash
docker tag 5af3818676dc 646456456452.dkr.ecr.us-west-2.amazonaws.com/production:V1 # v1
```

To confirm, run:

```bash
docker images
```

Docker push:

Adjust and then run the following command:

```bash
docker push <aws_account_id>.dkr.ecr.us-west-2.amazonaws.com/<my-repository:tag>
```

Example:

```bash
docker push 646456456452.dkr.ecr.us-west-2.amazonaws.com/homologation:V1 # v1
```

```bash
docker push 646456456452.dkr.ecr.us-west-2.amazonaws.com/production:V1 # v1
```

Wait until the process is finished; it may take a few minutes to complete. You should now have an image in ECR that corresponds to your locally built Docker image.

##### 3. Create the Docker run file

Each environment has a Docker run file. The Docker run file is used to create a container from an image on AWS ECR.

Go to `env/Prod` and create a file named `Dockerrun.aws.json`.

See how to fill the file: https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/single-container-docker-configuration.html

If we need to authenticate into our repository because we are not using our AWS account, see https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/single-container-docker-configuration.html#docker-configuration.remote-repo.

But in our case, as we are authenticated, we just can use this:
https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/single-container-docker-configuration.html#docker-configuration.no-compose

Insert and modify the following content in it:

```json
{
  "AWSEBDockerrunVersion": "1",
  "Image": {
    "Name": "docker push full-path",
    "Update": "true",
    "UpdateStrategy": "rolling"
  },
  "Ports": [
    {
      "ContainerPort": <Dockerfile EXPOSE port>,
      "HostPort": <Dockerfile EXPOSE port>
    }
  ]
}
```

Example:

Homologation environment:

```json
{
  "AWSEBDockerrunVersion": "1",
  "Image": {
    "Name": "646456456452.dkr.ecr.us-west-2.amazonaws.com/homologation:V1",
    "Update": "true",
    "UpdateStrategy": "rolling"
  },
  "Ports": [
    {
      "ContainerPort": 8000,
      "HostPort": 8000
    }
  ]
}
```

Production environment:

```json
{
  "AWSEBDockerrunVersion": "1",
  "Image": {
    "Name": "646456456452.dkr.ecr.us-west-2.amazonaws.com/production:V1",
    "Update": "true",
    "UpdateStrategy": "rolling"
  },
  "Ports": [
    {
      "ContainerPort": 8000,
      "HostPort": 8000
    }
  ]
}
```
###### Other environments

Create `Dockerrun.aws.json` file for each environment, don´t forget to edit the name field accordingly to the environment.

Example for homologation environment:

```json
{
  "AWSEBDockerrunVersion": "1",
  "Image": {
    "Name": "646456456452.dkr.ecr.us-west-2.amazonaws.com/homologation:V1",
    "Update": "true",
    "UpdateStrategy": "rolling"
  },
  "Ports": [
    {
      "ContainerPort": 8000,
      "HostPort": 8000
    }
  ]
}
```

##### 4. Upload to S3 bucket

AWS Elastic Beanstalk only accepts ZIP files with a .zip extension. You will need to compress your application into a single file before uploading it.

The `Dockerrun.aws.json` file must be zipped first:

At the file's directory, run:

Homologation directory:

```bash
zip -r homologation.zip Dockerrun.aws.json
```

Production directory:

```bash
zip -r production.zip Dockerrun.aws.json
```

**Note**

You can do the steps above (from `2. Run docker images`) to create a Homologation (homologation) environment, which will automatically be created as an Environment in Elastic Beanstalk when you upload your zip file.

**End of Note**

Create a new `.tf` file at `infra/` directory, for example, `S3.tf`.

See: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket

Inside, add and adjust accordingly the following code:

```terraform
resource "aws_s3_bucket" "beanstalk_deploys" {
  bucket = "${var.name}-deploys"

  tags = { # optional, but recommended using tags
    Name        = "${var.name}-deploys"
    Environment = "${var.name}"
  }
}
```

Now see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object

In the same S3.tf file, add:

```terraform
resource "aws_s3_object" "docker" {
  depends_on = [ aws_s3_bucket.beanstalk_deploys ] # Necessary as Terraform will try to upload the file even before the S3 bucket is created, resulting in errors.
  bucket = "${var.name}-deploys"
  key    = "${var.name}.zip" # object name at S3
  source = "<path/to/file>" # for example "${var.name}.zip"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("path/to/file") # for example "${var.name}.zip"
}
```

##### 5. Create an application version for Elastic Beanstalk

See: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elastic_beanstalk_application_version

At `infra/beanstalk.tf` file, add:

```terraform
resource "aws_elastic_beanstalk_application_version" "default" {
  depends_on = [ aws_elastic_beanstalk_environment.beanstalk_environment,
aws_elastic_beanstalk_application.beanstalk_application,
aws_s3_object.docker ]
  name        = var.environment
  application = var.name
  description = var.description
  bucket      = aws_s3_bucket.<S3.tf aws_s3_bucket name>.id # beanstalk_deploys
  key         = aws_s3_object.<S3.tf aws_s3_object name>.id # docker
}
```

##### 6. Deploying the application

At the Terminal, go to the environment directory and run the following command:

```bash
terraform apply
```

##### 7. Check the deployment

Open the AWS console in the browser and check if everything was correctly deployed. S3 bucket, ECR and Elastic Beanstalk.

At Elastic Beanstalk, you can see that there's no version running. You can run a version manually through the console, or you can do it through the Terminal.

Through the Terminal, you can run the following command:

```bash
aws elasticbeanstalk update-environment --environment-name <your Environment Name> --version-label <Version label found at Application: <Environment Name> - Application versions>
```

In our example:

Homologation environment:

```bash
aws elasticbeanstalk update-environment --environment-name homologation-environment --version-label homologation-environment
```

Production environment:

```bash
aws elasticbeanstalk update-environment --environment-name production-environment --version-label production-environment
```

Now go to the AWS Elastic Beanstalk console at https://console.aws.amazon.com/elasticbeanstalk/home

Make sure you are in the deployment region, then go to Environments and click the deployed environment, in our example, `production-environment`.

Verify if there's a Domain, and open it in the browser. It should be running.

That's it! You should now have an AWS Elastic Beanstalk Environment up and running with Docker.

For real projects, you should have more environments like Homologation. Just create a new docker tag and configure the environment.

You may want to undo everything that was done or create another environment for testing purposes. To do so, simply run `terraform destroy`. You may need first to delete manually the ECR image resources at the AWS console.
