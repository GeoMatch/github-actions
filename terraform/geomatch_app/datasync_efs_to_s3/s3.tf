resource "aws_s3_bucket" "this" {
  bucket = "${local.name_prefix}-destination"

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}
# In other places, we'd enable ACLs.
# But Amazon is recommending against it.
