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

resource "aws_iam_instance_profile" "beanstalk_ec2_profile" {
  name = "beanstalk-ec2-profile-${var.name}"
  role = aws_iam_role.beanstalk_ec2.name
  
}