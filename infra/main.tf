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
  source    = "./modules/alb"
  subnet_id = module.network.subnet_id
  alb_sg_id = module.network.alb_sg_id
}

module "ecs" {
  source           = "./modules/ecs"
  account_id       = var.account_id
  region           = var.aws_region
  subnet_id        = module.network.subnet_id
  ecs_sg_id        = module.network.ecs_sg_id
  target_group_arn = module.alb.target_group_arn
  project_name     = var.project_name
  env              = var.env
}

