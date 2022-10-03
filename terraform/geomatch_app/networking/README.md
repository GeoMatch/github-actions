Instead of relying on output for subnets, use the VPC ID output and data resources:

```hcl
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.networking_module.vpc_id]
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    Tier        = [var.networking_module.private_tier_tag]
  }
}
```