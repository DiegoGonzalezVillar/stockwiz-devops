project_name = "stockwiz"
env          = "test"
aws_region   = "us-east-1"

vpc_cidr = "10.1.0.0/16"

ecr_repositories = [
  "api-gateway",
  "product-service",
  "inventory-service",
  "postgres"
]

api_image        = "placeholder"
postgres_image   = "placeholder"
redis_image      = "redis:7-alpine"
