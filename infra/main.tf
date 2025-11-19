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
  environment = var.env # antes var.environment
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

module "ecs_cluster" {
  source              = "./modules/ecs_cluster"
  environment         = var.env
  cluster_name        = "ecs-cluster-dev"
  vpc_id              = module.vpc.vpc_id
  private_subnets_ids = module.vpc.private_subnets_ids
  ecs_sg_id           = module.vpc.ecs_sg_id
  instance_type       = "t3.micro"
  desired_capacity    = 1
}

module "ecs_services" {
  source              = "./modules/ecs_services"
  environment         = var.env
  cluster_name        = module.ecs_cluster.cluster_name
  private_subnets_ids = module.vpc.private_subnets_ids
  public_subnets_ids = module.vpc.public_subnets_ids
  ecs_sg_id           = module.vpc.ecs_sg_id
  gateway_tg_arn      = module.alb.gateway_tg_arn

  #imagenes de Docker
  gateway_image   = "${module.ecr.repo_uris["api-gateway"]}:${var.env}-latest"
  product_image   = "${module.ecr.repo_uris["product-service"]}:${var.env}-latest"
  inventory_image = "${module.ecr.repo_uris["inventory-service"]}:${var.env}-latest"
}
