locals {
  name_prefix = "${var.project_name}-${var.env}"
}

# -------------------------
# 1) ECR
# -------------------------
module "ecr" {
  source       = "./modules/ecr"
  name_prefix  = local.name_prefix
  repositories = var.ecr_repositories
}

# -------------------------
# 2) VPC
# -------------------------
module "vpc" {
  source      = "./modules/vpc"
  environment = var.env
  vpc_cidr    = var.vpc_cidr
}

# -------------------------
# 3) ALB PÚBLICO (API Gateway)
# -------------------------
module "alb" {
  source             = "./modules/alb"
  environment        = var.env
  vpc_id             = module.vpc.vpc_id
  public_subnets_ids = module.vpc.public_subnets_ids
  alb_sg_id          = module.vpc.alb_sg_id
  gateway_port       = 8000
}

# -------------------------
# 4) ECS CLUSTER
# -------------------------
resource "aws_ecs_cluster" "fargate" {
  name = "ecs-fargate-cluster-${var.env}"

  tags = {
    Name        = "ecs-fargate-cluster-${var.env}"
    Environment = var.env
  }
}

# -------------------------
# 5) ALBs INTERNOS (product, inventory, dbcache)
# -------------------------

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

module "alb_dbcache" {
  source          = "./modules/alb_internal"
  name            = "${var.env}-dbcache"
  environment     = var.env
  sg_id           = module.vpc.ecs_sg_id
  private_subnets = module.vpc.private_subnets_ids
  vpc_id          = module.vpc.vpc_id
  port            = 5432
}

# -------------------------
# 6) ECS SERVICES
# -------------------------

module "ecs_services" {
  source              = "./modules/ecs_services"
  environment         = var.env
  cluster_name        = "ecs-fargate-cluster-${var.env}"

  # Networking
  public_subnets_ids  = module.vpc.public_subnets_ids
  private_subnets_ids = module.vpc.private_subnets_ids
  ecs_sg_id           = module.vpc.ecs_sg_id
  vpc_id              = module.vpc.vpc_id

  # ALB publico (gateway)
  gateway_tg_arn = module.alb.gateway_tg_arn

  # ALBs internos
  tg_product_arn   = module.alb_product.target_group_arn
  tg_inventory_arn = module.alb_inventory.target_group_arn
  tg_dbcache_arn   = module.alb_dbcache.target_group_arn

  # Imágenes
  gateway_image       = "${module.ecr.repo_uris["api-gateway"]}:${var.env}-latest"
  product_image       = "${module.ecr.repo_uris["product-service"]}:${var.env}-latest"
  inventory_image     = "${module.ecr.repo_uris["inventory-service"]}:${var.env}-latest"

  # DNS internos
  dns_product   = module.alb_product.alb_dns_name
  dns_inventory = module.alb_inventory.alb_dns_name
  dns_dbcache   = module.alb_dbcache.alb_dns_name
}


