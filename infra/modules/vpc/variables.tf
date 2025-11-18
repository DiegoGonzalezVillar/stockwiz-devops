variable "environment" {
  type        = string
  description = "Environment name (dev, test, prod)"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}
