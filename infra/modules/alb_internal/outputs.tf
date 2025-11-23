output "alb_dns_name" {
  description = "DNS interno del ALB"
  value       = aws_lb.this.dns_name
}

output "alb_arn" {
  description = "ARN del ALB interno"
  value       = aws_lb.this.arn
}

output "target_group_arn" {
  description = "ARN del target group interno"
  value       = aws_lb_target_group.this.arn
}

output "listener_arn" {
  description = "ARN del listener interno"
  value       = aws_lb_listener.this.arn
}
