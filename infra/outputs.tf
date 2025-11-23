###############################################
# ALB PÚBLICO (API Gateway)
###############################################

output "alb_public_dns_name" {
  description = "DNS público del ALB"
  value       = module.alb_public.alb_dns_name
}

output "gateway_target_group_arn" {
  description = "ARN del Target Group del API Gateway"
  value       = module.alb_public.gateway_tg_arn
}

###############################################
# ALBs INTERNOS
###############################################

output "product_alb_dns" {
  value = module.alb_product.alb_dns_name
}

output "inventory_alb_dns" {
  value = module.alb_inventory.alb_dns_name
}

###############################################
# ECS Cluster
###############################################

output "ecs_cluster_name" {
  value = aws_ecs_cluster.fargate.name
}

###############################################
# VPC Info
###############################################

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets_ids
}

output "private_subnets" {
  value = module.vpc.private_subnets_ids
}
