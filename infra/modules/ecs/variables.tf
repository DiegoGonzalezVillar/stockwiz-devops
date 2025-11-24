variable "account_id" {}
variable "region" {}
variable "public_subnets" {
  type = list(string)
}
variable "ecs_sg_id" {}
variable "target_group_arn" {}
variable "project_name" {}
variable "env" {}
