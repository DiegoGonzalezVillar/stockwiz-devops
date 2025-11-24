variable "project_name" {}
variable "env" {}
variable "aws_region" {}
variable "vpc_cidr" {}
variable "ecr_repositories" { type = list(string) }

variable "api_image" {}
variable "product_image" {}
variable "inventory_image" {}
variable "postgres_image" {}

