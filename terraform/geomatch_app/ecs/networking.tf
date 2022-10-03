data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.networking_module.vpc_id]
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    Tier        = var.networking_module.private_tier_tag
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.networking_module.vpc_id]
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    Tier        = var.networking_module.public_tier_tag
  }
}
