output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "gateway_tg_arn" {
  value = aws_lb_target_group.gateway.arn
}

