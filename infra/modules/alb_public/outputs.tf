output "alb_public_dns_name" {
  value = module.alb_public.alb_dns_name
}

output "alb_public_gateway_tg_arn" {
  value = module.alb_public.gateway_tg_arn
}
