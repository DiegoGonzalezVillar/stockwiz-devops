terraform {
  required_version = ">= 1.3.0"
  backend "s3" {}
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
}

############################################################
# NETWORK
############################################################
module "network" {
  source     = "./modules/network"
  vpc_cidr   = var.vpc_cidr
  aws_region = var.aws_region
}

############################################################
# ALB
############################################################
module "alb" {
  source         = "./modules/alb"
  public_subnets = module.network.public_subnets
  alb_sg_id      = module.network.alb_sg_id
  project_name   = var.project_name
  env            = var.env
}

############################################################
# ECR (repos)
############################################################
module "ecr" {
  source       = "./modules/ecr"
  name_prefix  = "${var.project_name}-${var.env}"
  repositories = var.ecr_repositories
}

############################################################
# ECS EC2 CLUSTER + SERVICES
############################################################
module "ecs_ec2" {
  source = "./modules/ecs-ec2"

  project_name          = var.project_name
  env                   = var.env
  public_subnets        = module.network.public_subnets
  vpc_id                = module.network.vpc_id
  ecs_sg_id             = module.network.ecs_sg_id
  alb_target_group_arn  = module.alb.target_group_arn

  # container images (from workflow)
  api_image        = var.api_image
  postgres_image   = var.postgres_image
  inventory_image  = var.inventory_image
  product_image    = var.product_image
  redis_image      = var.redis_image
}

