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

module "alb" {
  source         = "./modules/alb"
  public_subnets = module.network.public_subnets
  alb_sg_id      = module.network.alb_sg_id
  project_name   = var.project_name
  env            = var.env
}

module "ecr" {
  source       = "./modules/ecr"
  name_prefix  = "${var.project_name}-${var.env}"
  repositories = var.ecr_repositories
}

# 1. Llamada al Módulo de Secretos
module "secrets" {
  source             = "./modules/secrets"
  environment        = var.environment
  db_password_secret         = var.db_password_secret
  inventory_api_key_secret   = var.inventory_api_key_secret
}

module "ecs" {

  source = "./modules/ecs"
	

  project_name         = var.project_name
  env                  = var.env
  public_subnets       = module.network.public_subnets
  ecs_sg_id            = module.network.ecs_sg_id
  alb_target_group_arn = module.alb.target_group_arn
  aws_region = var.aws_region
  full_image = var.full_image
db_password_arn      = module.secrets.db_password_arn
  inventory_api_key_arn = module.secrets.inventory_api_key_arn
}

