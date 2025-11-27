output "alb_dns" {
  value = module.alb.alb_dns
}

#output "dashboard_name" {
#  value = aws_cloudwatch_dashboard.main.dashboard_name
#}

output "alb_dns_name" {
  value       = aws_lb.app_lb.dns_name 
  description = "The DNS name of the Application Load Balancer for accessing the API Gateway."
}

