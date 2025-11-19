variable "environment" {
  type        = string
  description = "Environment name (dev, test, prod)"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

#variable "ecs_service_name" {
#  description = "Name of the ECS service"
#  type        = string
#  default     = "my-service"
#}


variable "cluster_name" {
  type        = string
  description = "Nombre del ECS cluster"
}

variable "private_subnets_ids" {
  type        = list(string)
  description = "Subnets privadas donde corren las tareas ECS"
}

variable "ecs_sg_id" {
  type        = string
  description = "Security group para las tareas ECS"
}

variable "gateway_tg_arn" {
  type        = string
  description = "Target Group ARN del ALB para el api-gateway"
}

variable "gateway_image" {
  type        = string
  description = "Imagen de ECR para api-gateway"
}

variable "product_image" {
  type        = string
  description = "Imagen de ECR para product-service"
}

variable "inventory_image" {
  type        = string
  description = "Imagen de ECR para inventory-service"
}

variable "gateway_desired_count" {
  type    = number
  default = 1
}

variable "product_desired_count" {
  type    = number
  default = 1
}

variable "inventory_desired_count" {
  type    = number
  default = 1
}
