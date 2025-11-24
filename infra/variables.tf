variable "project_name" {}
variable "env" {}
variable "aws_region" {}
variable "vpc_cidr" {}

variable "ecr_repositories" { type = list(string) }

variable "full_image" {}

