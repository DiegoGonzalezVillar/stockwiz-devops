output "vpc_id" {
  value = aws_vpc.app_vpc.id
}

output "public_subnets_ids" {
  value = [for s in aws_subnet.public_subnets : s.id]
}

output "private_subnets_ids" {
  value = [for s in aws_subnet.private_subnets : s.id]
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "ecs_sg_id" {
  value = aws_security_group.ecs_sg.id
}
