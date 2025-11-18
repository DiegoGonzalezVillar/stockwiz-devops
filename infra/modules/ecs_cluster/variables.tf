variable "environment" {
  type        = string
  description = "Environment name (dev, test, prod)"
}

variable "cluster_name" {
  type        = string
  description = "Nombre del ECS cluster"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID (por si lo necesitás luego)"
}

variable "private_subnets_ids" {
  type        = list(string)
  description = "Subnets privadas para las instancias ECS"
}

variable "ecs_sg_id" {
  type        = string
  description = "Security group para las instancias ECS"
}

variable "instance_type" {
  type        = string
  description = "Tipo de instancia EC2 para el cluster ECS"
}

variable "desired_capacity" {
  type        = number
  description = "Cantidad deseada de instancias en el ASG"
  default     = 1
}

variable "min_size" {
  type        = number
  description = "Mínimo de instancias en el ASG"
  default     = 1
}

variable "max_size" {
  type        = number
  description = "Máximo de instancias en el ASG"
  default     = 1
}
