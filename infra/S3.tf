resource "aws_s3_bucket" "beanstalk_deploys" {
  bucket = "${var.name}-deploys"

  # tags = { # optional, but recommended using tags
  #   Name        = "${var.name}-deploys"
  #   Environment = "${var.name}"
  # }
}

resource "aws_s3_object" "docker" {
  depends_on = [ aws_s3_bucket.beanstalk_deploys ] # Terraform may try to upload the file at the same time the bucket is being created. `depends_on` ensures that the bucket is created before the object is
  bucket = "${var.name}-deploys"
  key    = "${var.name}.zip" # object name at S3
  source = "${var.name}.zip" # for example "${var.name}"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("${var.name}.zip") # for example "${var.name}.zip"
}