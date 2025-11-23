variable "project_name" {}
variable "env" {}
variable "aws_region" {}
variable "aws_profile" { default = "default" }
variable "vpc_cidr" {}
variable "ecr_repositories" { type = list(string) }
variable "account_id" {}
