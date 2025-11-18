output "vpc_id" {
  description = "ID de la VPC del entorno"
  value       = module.vpc.vpc_id
}

output "public_subnets_ids" {
  description = "Subnets públicas donde se ubica el ALB"
  value       = module.vpc.public_subnets_ids
}

output "private_subnets_ids" {
  description = "Subnets privadas donde corren las tareas ECS"
  value       = module.vpc.private_subnets_ids
}

output "alb_dns_name" {
  description = "DNS público del Application Load Balancer para acceder a la app"
  value       = module.alb.alb_dns_name
}

output "alb_arn" {
  description = "ARN del Application Load Balancer"
  value       = module.alb.alb_arn
}

output "ecs_cluster_name" {
  description = "Nombre del ECS Cluster donde corren los servicios"
  value       = module.ecs_cluster.cluster_name
}

output "alb_security_group_id" {
  description = "Security Group asociado al ALB"
  value       = module.vpc.alb_sg_id
}

output "ecs_security_group_id" {
  description = "Security Group usado por las instancias/tareas ECS"
  value       = module.vpc.ecs_sg_id
}

output "ecr_repo_uris" {
  description = "URIs de los repositorios ECR por servicio"
  value       = module.ecr.repo_uris
}
