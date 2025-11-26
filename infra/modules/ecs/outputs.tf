output "cluster_name" {
  value = aws_ecs_cluster.cluster.name
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.ecs.name
}