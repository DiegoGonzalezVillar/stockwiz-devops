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
# 3) ALB PÚBLICO (API Gateway)nuevo
# -------------------------
module "alb_public" {
  source             = "./modules/alb_public"
  environment        = var.env
  vpc_id             = module.vpc.vpc_id
  public_subnets_ids = module.vpc.public_subnets_ids
  alb_sg_id          = module.vpc.alb_sg_id
  gateway_port       = 8000
}

# -------------------------
# 4) ALB INTERNO (product + inventory)
# -------------------------
module "alb_internal" {
  source              = "./modules/alb_internal"
  environment         = var.env
  vpc_id              = module.vpc.vpc_id
  private_subnets_ids = module.vpc.private_subnets_ids
  alb_sg_id           = module.vpc.ecs_sg_id
}

# -------------------------
# 5) ECS CLUSTER
# -------------------------
resource "aws_ecs_cluster" "fargate" {
  name = "ecs-fargate-cluster-${var.env}"
}

# -------------------------
# 6) ECS SERVICES
# -------------------------
module "ecs_services" {
  source              = "./modules/ecs_services"
  environment         = var.env
  cluster_name        = "ecs-fargate-cluster-${var.env}"

  public_subnets_ids  = module.vpc.public_subnets_ids
  private_subnets_ids = module.vpc.private_subnets_ids
  ecs_sg_id           = module.vpc.ecs_sg_id
  vpc_id              = module.vpc.vpc_id

  gateway_tg_arn      = module.alb_public.gateway_tg_arn

  tg_product_arn      = module.alb_product.target_group_arn
  tg_inventory_arn    = module.alb_inventory.target_group_arn
  tg_dbcache_arn      = module.alb_dbcache.target_group_arn

  gateway_image       = "${module.ecr.repo_uris["api-gateway"]}:${var.env}-latest"
  product_image       = "${module.ecr.repo_uris["product-service"]}:${var.env}-latest"
  inventory_image     = "${module.ecr.repo_uris["inventory-service"]}:${var.env}-latest"

  dns_product   = module.alb_product.alb_dns_name
  dns_inventory = module.alb_inventory.alb_dns_name
  dns_dbcache   = module.alb_dbcache.alb_dns_name

  aws_region = var.aws_region  
}
