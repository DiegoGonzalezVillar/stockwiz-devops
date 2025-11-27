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
  project_name  = var.project_name
  env           = var.env
  aws_region = var.aws_region
}

module "alb" {
  source         = "./modules/alb"
  public_subnets = module.network.public_subnets
  alb_sg_id      = module.network.alb_sg_id
  project_name   = var.project_name
  env            = var.env
  vpc_id = module.network.vpc_id
}

module "ecr" {
  source       = "./modules/ecr"
  name_prefix  = "${var.project_name}-${var.env}"
  repositories = var.ecr_repositories
}

module "secrets" {
  source             = "./modules/secrets"
  env        = var.env
  db_password_secret         = var.db_password_secret
  inventory_api_key_secret   = var.inventory_api_key_secret
}

data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

module "notifier" {
  source        = "./modules/notifier"
  project_name  = var.project_name
  env           = var.env
  aws_region    = var.aws_region
  alert_email   = var.alert_email 
  lab_role_arn  = data.aws_iam_role.lab_role.arn
}

module "monitoring" {
  source       = "./modules/monitoring"
  project_name = var.project_name
  env          = var.env
  aws_region   = var.aws_region
  
  alb_arn_suffix = module.alb.alb_arn_suffix 
}

module "ecs" {
  source = "./modules/ecs"
  project_name         = var.project_name
  env                  = var.env
  private_subnet_ids   = module.network.private_subnets
  ecs_sg_id            = module.network.ecs_sg_id
  alb_target_group_arn = module.alb.target_group_arn
  aws_region = var.aws_region
  full_image = var.full_image
  db_password_arn      = module.secrets.db_password_arn
  inventory_api_key_arn = module.secrets.inventory_api_key_arn
}

