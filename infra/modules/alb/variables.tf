variable "environment" {
  type        = string
  description = "Environment name (dev, test, prod)"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID donde vive el ALB"
}

variable "public_subnets_ids" {
  type        = list(string)
  description = "Subnets públicas para el ALB"
}

variable "alb_sg_id" {
  type        = string
  description = "Security group del ALB"
}

variable "gateway_port" {
  type        = number
  description = "Puerto del api-gateway detrás del ALB"
  default     = 8000
}
