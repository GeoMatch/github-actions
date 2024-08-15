TODO:
- Environment variables 
- ECR Url as variable
- Allow for S3 in task IAM (and as dynamic variable). Might have to create VPC endpoint?
- See alb module for new variables (AWS login)
- remove default rstudio user 

TODO(ideal):
- Move SFTP over to EFS (with a copy step to S3 in case of duplicate uploads by partner)
  - would need to recreate SFTP server in all likely hood (start with prod since COA prod hasn't been deployed yet)

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