variable "project_name" {}
variable "env" {}
variable "public_subnets" { type = list(string) }
variable "private_subnet_ids" {
  description = "IDs de las subredes privadas donde se lanzarán las Tasks de ECS Fargate."
  type        = list(string)
}
variable "ecs_sg_id" {}
variable "aws_region" {
  type = string
}

variable "alb_target_group_arn" {}
variable "full_image" {}

variable "db_password_arn" {
  description = "ARN del secreto de AWS Secrets Manager para la contraseña de la DB."
  type        = string
}

variable "inventory_api_key_arn" {
  description = "ARN del secreto de AWS Secrets Manager para la clave de la API de inventario."
  type        = string
}

