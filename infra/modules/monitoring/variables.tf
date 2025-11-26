variable "project_name" {
  type = string
}

variable "env" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "alb_arn_suffix" {
  description = "El ARN Suffix (ID) del ALB necesario para referenciar las métricas del LoadBalancer."
  type = string
}