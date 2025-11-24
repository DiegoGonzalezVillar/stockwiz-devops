variable "project_name" {}
variable "env" {}
variable "public_subnets" {
  type = list(string)
}
variable "vpc_id" {}
variable "ecs_sg_id" {}
variable "alb_target_group_arn" {}
variable "instance_type" {
  default = "t3.medium"
}
variable "desired_capacity" {
  default = 1
}
variable "max_capacity" {
  default = 2
}
variable "api_image" {}
variable "postgres_image" {}
variable "redis_image" {
  default = "redis:7-alpine"
}
