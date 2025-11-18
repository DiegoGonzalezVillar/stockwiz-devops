output "gateway_service_name" {
  value = aws_ecs_service.gateway.name
}

output "product_service_name" {
  value = aws_ecs_service.product.name
}

output "inventory_service_name" {
  value = aws_ecs_service.inventory.name
}
