variable "project_name" {}
variable "env" {}
variable "aws_region" {}
variable "vpc_cidr" {}

variable "ecr_repositories" { type = list(string) }

variable "full_image" {
  type    = string
  default = ""
}

variable "db_password_secret" {
  description = "Contraseña segura de la base de datos (inyectada desde GitHub Secrets/CI)."
  type        = string
  sensitive   = true
}

variable "inventory_api_key_secret" {
  description = "Clave segura para la API interna (inyectada desde GitHub Secrets/CI)."
  type        = string
  sensitive   = true
}

