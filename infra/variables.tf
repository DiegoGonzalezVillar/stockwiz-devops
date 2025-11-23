variable "project_name" {
  type = string
}

variable "env" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "ecr_repositories" {
  type = list(string)
}

##############################################
# These go straight to the modules
##############################################
variable "gateway_port" {
  type    = number
  default = 8000
}
