resource "aws_datasync_location_efs" "destination" {
  access_point_arn            = aws_efs_access_point.this.arn
  efs_file_system_arn         = module.sftp_efs.file_system_arn
  file_system_access_role_arn = aws_iam_role.datasync_efs.arn
  in_transit_encryption       = "TLS1_2"
  subdirectory                = "/"

  ec2_config {
    security_group_arns = [aws_security_group.efs.arn]
    # AWS manages network interfaces:
    subnet_arn = data.aws_subnet.one_zone_private.arn
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    UserId      = var.user_id
  }
}

resource "aws_iam_role" "datasync_efs" {
  name = "${local.name_prefix}-datasync-efs"

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

resource "aws_iam_role_policy" "datasync_efs" {
  name = "${local.name_prefix}-datasync-efs-policy"
  role = aws_iam_role.datasync_efs.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "efs:ClientMount",
          "efs:ClientWrite",
          "efs:ClientRootAccess"
        ],
        Principal = {
          "AWS" = aws_iam_role.datasync_efs.arn
        },
        Effect   = "Allow",
        Resource = [module.sftp_efs.file_system_arn],
        Condition = {
          Bool = {
            "aws:SecureTransport" = "true"
          },
          StringEquals = {
            "elasticfilesystem:AccessPointArn" = aws_efs_access_point.this.arn
          }
        }
      }
    ]
  })
}
