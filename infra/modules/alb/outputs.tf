output "alb_dns" {
  description = "Nombre DNS del Application Load Balancer."
  value       = aws_lb.app_lb.dns_name
}

output "target_group_arn" {
  description = "ARN del Target Group (TG) principal."
  value       = aws_lb_target_group.tg.arn
}

output "alb_arn_suffix" {
  description = "El ARN Suffix (ID) del ALB necesario para CloudWatch Metrics."
  value       = aws_lb.app_lb.arn_suffix
}

output "alb_dns_name" {
  value       = aws_lb.app_lb.dns_name 
  description = "The DNS name of the Application Load Balancer."
}

