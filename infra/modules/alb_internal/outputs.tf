output "alb_dns_name" {
  value = aws_lb.internal.dns_name
}

output "product_tg_arn" {
  value = aws_lb_target_group.product.arn
}

output "inventory_tg_arn" {
  value = aws_lb_target_group.inventory.arn
}
