project_name = "stockwiz"
env          = "dev"
aws_region   = "us-east-1"

vpc_cidr = "10.0.0.0/16"

# repos que se crean en AWS ECR
ecr_repositories = [
  "api-gateway",
  "product-service",
  "inventory-service",
  "postgres"
]

api_image        = "placeholder"
postgres_image   = "placeholder"
redis_image      = "redis:7-alpine"

