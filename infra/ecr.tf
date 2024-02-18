resource "aws_ecr_repository" "ecrRepository" {
  name                 = "var.name"
  image_tag_mutability = "MUTABLE" # Optional. Default is MUTABLE.

  # image_scanning_configuration { # Optional. By default, image scanning must be manually triggered.
  #  scan_on_push = true
  #}

}