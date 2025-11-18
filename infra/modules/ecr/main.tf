resource "aws_ecr_repository" "repos" {
  for_each = toset(var.repositories)

  name                 = "${var.name_prefix}/${each.key}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
  force_delete = true
  tags         = { Project = var.name_prefix, Service = each.key }
}
