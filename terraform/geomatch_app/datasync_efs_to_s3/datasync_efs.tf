data "aws_security_group" "efs_mount_target" {
  id = module.sftp_efs.mount_target_sg_id
}

locals {
  root_uid = 0
}

resource "aws_efs_access_point" "this" {
  file_system_id = var.efs_module.file_system_id

  # Read as root 
  posix_user {
    gid = local.root_uid
    uid = local.root_uid
  }

  root_directory {
    path = "/"
    # No files should be created
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "${local.name_prefix}-efs-read-datasync-ap"
  }
}

resource "aws_datasync_location_efs" "source" {
  access_point_arn            = aws_efs_access_point.this.arn
  efs_file_system_arn         = var.efs_module.file_system_arn
  file_system_access_role_arn = aws_iam_role.datasync_efs.arn
  in_transit_encryption       = "TLS1_2"
  subdirectory                = "/"

  ec2_config {
    security_group_arns = [data.aws_security_group.efs_mount_target.arn]
    # AWS manages network interfaces:
    subnet_arn = data.aws_subnet.one_zone_private.arn
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "${local.name_prefix}-efs-source"
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
  }
}

data "aws_iam_policy_document" "root_fs_access" {
  statement {
    sid = "${local.name_prefix}-root-fs-access"
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:ClientRootAccess"
    ]
    effect = "Allow"
    resources = [
      var.efs_module.file_system_arn
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.datasync_efs.arn]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["true"]
    }
    condition {
      test     = "StringEquals"
      variable = "elasticfilesystem:AccessPointArn"
      values   = [aws_efs_access_point.this.arn]
    }
  }
}
