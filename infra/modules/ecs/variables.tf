variable "project_name" {}
variable "env" {}
variable "public_subnets" { type = list(string) }
variable "ecs_sg_id" {}
variable "aws_region" {
  type = string
}

variable "alb_target_group_arn" {}
variable "full_image" {}
