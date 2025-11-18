variable "project_name" { type = string }
variable "env"          { type = string }
variable "aws_region"   { type = string }
variable "aws_profile"  { type = string }

variable "ecr_repositories" {
  type    = list(string)
  default = ["api-gateway", "product-service", "inventory-service"]
}
