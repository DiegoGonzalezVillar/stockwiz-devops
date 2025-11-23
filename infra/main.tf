locals {
  name_prefix = "${var.project_name}-${var.env}"
}

###############################################
# 1) ECR
###############################################
module "ecr" {
  source       = "./modules/ecr"
  name_prefix  = local.name_prefix
  repositories = var.ecr_repositories
}

###############################################
# 2) VPC
###############################################
module "vpc" {
  source      = "./modules/vpc"
  environment = var.env
  vpc_cidr    = var.vpc_cidr
}

###############################################
# 3) ALB PÚBLICO (solo para el API Gateway)
###############################################
module "alb_public" {
  source             = "./modules/alb_public"
  environment        = var.env
  vpc_id             = module.vpc.vpc_id
  public_subnets_ids = module.vpc.public_subnets_ids
  alb_sg_id          = module.vpc.alb_sg_id
  gateway_port       = var.gateway_port
}

###############################################
# 4) ALBs INTERNOS (solo product e inventory)
###############################################

module "alb_product" {
  source          = "./modules/alb_internal"
  name            = "${var.env}-product"
  environment     = var.env
  sg_id           = module.vpc.ecs_sg_id
  private_subnets = module.vpc.private_subnets_ids
  vpc_id          = module.vpc.vpc_id
  port            = 8001
}

module "alb_inventory" {
  source          = "./modules/alb_internal"
  name            = "${var.env}-inventory"
  environment     = var.env
  sg_id           = module.vpc.ecs_sg_id
  private_subnets = module.vpc.private_subnets_ids
  vpc_id          = module.vpc.vpc_id
  port            = 8002
}

###############################################
# 5) ECS CLUSTER
###############################################
resource "aws_ecs_cluster" "fargate" {
  name = "ecs-fargate-cluster-${var.env}"

  tags = {
    Name        = "ecs-fargate-cluster-${var.env}"
    Environment = var.env
  }
}

###############################################
# 6) ECS SERVICIOS
###############################################
module "ecs_services" {
  source       = "./modules/ecs_services"
  environment  = var.env
  cluster_name = "ecs-fargate-cluster-${var.env}"

  # Networking
  public_subnets_ids  = module.vpc.public_subnets_ids
  private_subnets_ids = module.vpc.private_subnets_ids
  ecs_sg_id           = module.vpc.ecs_sg_id
  vpc_id              = module.vpc.vpc_id

  # Public ALB
  gateway_tg_arn = module.alb_public.gateway_tg_arn

  # Internal ALBs
  tg_product_arn   = module.alb_product.target_group_arn
  tg_inventory_arn = module.alb_inventory.target_group_arn

  # Internal DNS
  dns_product   = module.alb_product.alb_dns_name
  dns_inventory = module.alb_inventory.alb_dns_name

  # Images
  gateway_image   = "${module.ecr.repo_uris["api-gateway"]}:${var.env}-latest"
  product_image   = "${module.ecr.repo_uris["product-service"]}:${var.env}-latest"
  inventory_image = "${module.ecr.repo_uris["inventory-service"]}:${var.env}-latest"

  # Region
  aws_region = var.aws_region
}
