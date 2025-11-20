locals {
  name_prefix = "${var.project_name}-${var.env}"
}

module "ecr" {
  source       = "./modules/ecr"
  name_prefix  = local.name_prefix
  repositories = var.ecr_repositories
}

module "vpc" {
  source      = "./modules/vpc"
  environment = var.env
  vpc_cidr    = var.vpc_cidr
}

module "alb" {
  source             = "./modules/alb"
  environment        = var.env
  vpc_id             = module.vpc.vpc_id
  public_subnets_ids = module.vpc.public_subnets_ids
  alb_sg_id          = module.vpc.alb_sg_id
  gateway_port       = 8000
}

resource "aws_ecs_cluster" "fargate" {
  name = "ecs-fargate-cluster-${var.env}"

  tags = {
    Name        = "ecs-fargate-cluster-${var.env}"
    Environment = var.env
  }
}

module "ecs_services" {
  source             = "./modules/ecs_services"
  environment        = var.env
  cluster_name       = "ecs-fargate-cluster-${var.env}"
  public_subnets_ids = module.vpc.public_subnets_ids
  ecs_sg_id          = module.vpc.ecs_sg_id
  gateway_tg_arn     = module.alb.gateway_tg_arn

  gateway_image   = "${module.ecr.repo_uris["api-gateway"]}:${var.env}-latest"
  product_image   = "${module.ecr.repo_uris["product-service"]}:${var.env}-latest"
  inventory_image = "${module.ecr.repo_uris["inventory-service"]}:${var.env}-latest"
}

