terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
backend "s3" {
    bucket = "stockwiz-dev-tf-backend"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
  }
}

