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

module "network" {
  source     = "./modules/network"
  vpc_cidr   = var.vpc_cidr
  aws_region = var.aws_region
}

module "ecr" {
  source       = "./modules/ecr"
  name_prefix  = "${var.project_name}-${var.env}"
  repositories = var.ecr_repositories
}

module "alb" {
  source         = "./modules/alb"
  public_subnets = module.network.public_subnets
  alb_sg_id      = module.network.alb_sg_id
  project_name   = var.project_name
  env            = var.env
}


module "ecs" {
  source           = "./modules/ecs"
  region           = var.aws_region
  public_subnets   = module.network.public_subnets
  ecs_sg_id        = module.network.ecs_sg_id
  target_group_arn = module.alb.target_group_arn
  project_name     = var.project_name
  env              = var.env
}


