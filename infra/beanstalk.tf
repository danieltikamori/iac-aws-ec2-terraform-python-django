resource "aws_elastic_beanstalk_application" "beanstalk_application" {
  name        = var.name
  description = var.description
}

resource "aws_elastic_beanstalk_environment" "beanstalk_environment" {
  name                = var.environment
  application         = aws_elastic_beanstalk_application.beanstalk_application.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.2.1 running Docker" # see: https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/concepts.platforms.html#concepts.platforms.list In our case, use Docker: https://docs.aws.amazon.com/elasticbeanstalk/latest/platforms/platforms-supported.html#platforms-supported.docker Copy the description and paste at solution_stack_name

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
}

resource "aws_elastic_beanstalk_application_version" "default" {
  depends_on = [ aws_elastic_beanstalk_environment.beanstalk_environment,
  aws_elastic_beanstalk_application.beanstalk_application,
  aws_s3_object.docker ]
  name        = var.environment
  application = var.name
  description = var.description
  bucket      = aws_s3_bucket.beanstalk_deploys.id
  key         = aws_s3_object.docker.id
}