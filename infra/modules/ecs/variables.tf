variable "public_subnets" {
  type = list(string)
}

variable "ecs_sg_id" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "project_name" {
  type = string
}

variable "env" {
  type = string
}

variable "region" {
  type = string
}

variable "enabled" {
  type    = bool
  default = true
}


variable "api_image" {
  type = string
}

variable "product_image" {
  type = string
}

variable "inventory_image" {
  type = string
}

variable "postgres_image" {
  type = string
}
