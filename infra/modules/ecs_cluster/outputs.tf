output "cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  value = aws_ecs_cluster.this.arn
}

output "asg_name" {
  value = aws_autoscaling_group.ecs_asg.name
}
