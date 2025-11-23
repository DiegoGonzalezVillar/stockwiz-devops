variable "environment" { type = string }
variable "cluster_name" { type = string }

variable "public_subnets_ids" { type = list(string) }
variable "private_subnets_ids" { type = list(string) }

variable "ecs_sg_id" { type = string }
variable "vpc_id" { type = string }

variable "gateway_tg_arn" { type = string }
variable "tg_product_arn" { type = string }
variable "tg_inventory_arn" { type = string }
variable "tg_dbcache_arn" { type = string }

variable "dns_product" { type = string }
variable "dns_inventory" { type = string }
variable "dns_dbcache" { type = string }

variable "gateway_image" { type = string }
variable "product_image" { type = string }
variable "inventory_image" { type = string }

variable "aws_region" {
  type    = string
  default = "us-east-1"
}
