resource "aws_datasync_location_s3" "source" {
  s3_bucket_arn = aws_s3_bucket.this.arn
  subdirectory  = "/"

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_s3.arn
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    UserId      = var.user_id
  }
}

resource "aws_iam_role" "datasync_s3" {
  name = "${local.name_prefix}-datasync-s3"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "datasync.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Project     = var.project
    Environment = var.environment
    UserId      = var.user_id
  }
}

resource "aws_iam_role_policy" "datasync_s3" {
  role = aws_iam_role.datasync_s3.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:GetObject"
        ],
        Effect = "Allow",
        Resource = [
          "${aws_datasync_location_s3.source.s3_bucket_arn}",
        ]
      },
      {
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionTagging",
          "s3:ListMultipartUploadParts"
        ],
        Effect = "Allow",
        Resource = [
          "${aws_datasync_location_s3.source.s3_bucket_arn}/*"
        ]
      },
    ]
  })
}
