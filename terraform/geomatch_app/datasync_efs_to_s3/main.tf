terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
  }

  required_version = ">= 1.1.8"
}

locals {
  vpc_id      = var.networking_module.vpc_id
  name_prefix = "${var.project}-${var.environment}-${var.name_suffix}"
}

data "aws_subnet" "one_zone_private" {
  id = var.networking_module.one_zone_private_subnet_id
}
