variable "name" {
  type        = string
  description = "Prefijo del ALB interno por servicio"
}

variable "environment" {
  type        = string
  description = "Ambiente (dev, test, prod)"
}

variable "sg_id" {
  type        = string
  description = "Security group que permitirá tráfico interno"
}

variable "private_subnets" {
  type        = list(string)
  description = "Subnets privadas para el ALB interno"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "port" {
  type        = number
  description = "Puerto del servicio"
}
