variable "environment" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "public_subnets_ids" {
  type = list(string)
}

variable "private_subnets_ids" {
  type = list(string)
}

variable "ecs_sg_id" {
  type = string
}

# -----------------------------
# ALBs / Target Groups internos
# -----------------------------

# TG del API Gateway (este sigue existiendo y es externo)
variable "gateway_tg_arn" {
  type = string
}

# Target Groups internos
variable "tg_product_arn" {
  type = string
}

variable "tg_inventory_arn" {
  type = string
}

variable "tg_dbcache_arn" {
  type = string
}

# -----------------------------
# DNS internos de los servicios
# -----------------------------
# Estos vienen desde Route53 Private Hosted Zone
# y reemplazan los nombres tipo 'product', 'inventory', 'dbcache'

variable "dns_product" {
  type = string
}

variable "dns_inventory" {
  type = string
}

variable "dns_dbcache" {
  type = string
}

# -----------------------------
# Imágenes ECS
# -----------------------------

variable "gateway_image" {
  type = string
}

variable "product_image" {
  type = string
}

variable "inventory_image" {
  type = string
}

# -----------------------------

variable "vpc_id" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}
