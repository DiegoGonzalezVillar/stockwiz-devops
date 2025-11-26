output "alb_dns" {
  value = module.alb.alb_dns
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.main.dashboard_name
}


