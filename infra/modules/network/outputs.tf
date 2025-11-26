output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = aws_subnet.public_subnet[*].id
}

output "ecs_sg_id" {
  value = aws_security_group.ecs_sg.id
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "private_subnets" {
  description = "IDs de las subredes privadas para ECS Tasks."
  value       = aws_subnet.private_subnet[*].id
}
