variable "project_name" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment (dev, test, prod)"
  type        = string
}

variable "aws_region" {
  type = string
}


variable "ecr_repositories" {
  type    = list(string)
  default = ["api-gateway", "product-service", "inventory-service"]
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}





