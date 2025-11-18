locals {
  name_prefix = "${var.project_name}-${var.env}"
}

module "ecr" {
  source       = "./modules/ecr"
  name_prefix  = local.name_prefix
  repositories = var.ecr_repositories
}
