variable "project_name" {}
variable "env" {}
variable "aws_region" {}
variable "vpc_cidr" {}

variable "ecr_repositories" {
  type = list(string)
}

# image vars (ECR)
variable "api_image" {}
variable "postgres_image" {}
variable "redis_image" {
  default = "redis:7-alpine"
}

