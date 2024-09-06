data "aws_security_group" "efs_mount_target" {
  id = module.sftp_efs.mount_target_sg_id
}

module "sftp_efs" {
  source = "../efs"

  efs_name_prefix   = "-sftp-${var.user_id}"
  aws_region        = var.aws_region
  project           = var.project
  environment       = var.environment
  networking_module = var.networking_module
  ssm_name_prefix   = local.ssm_name_prefix

  extra_fs_policy_documents_json = data.aws_iam_policy_document.root_fs_access.json
}

resource "aws_efs_mount_target" "this" {
  file_system_id  = module.sftp_efs.file_system_id
  subnet_id       = var.networking_module.one_zone_private_subnet_id
  security_groups = [module.sftp_efs.mount_target_sg_id]
}

locals {
  root_uid = 0
}

resource "aws_efs_access_point" "this" {
  file_system_id = module.sftp_efs.file_system_id

  # Creates root user access point for DataSync
  # All files will be owned by root 
  # Root squashing is disabled due to ClientRootAccess IAM permission
  # See https://repost.aws/knowledge-center/efs-access-point-configurations
  posix_user {
    gid = local.root_uid
    uid = local.root_uid
  }

  root_directory {
    path = "/"

    # I think it's possible that these aren't actually
    # used and 777 root directory is created automatically.
    # creation_info {
    #   owner_uid   = local.root_uid
    #   owner_gid   = local.root_uid
    #   permissions = "0644" # Read only for everyone but root
    # }
  }
  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "${local.name_prefix}-efs-datasync-ap"
  }
}

resource "aws_datasync_location_efs" "destination" {
  access_point_arn            = aws_efs_access_point.this.arn
  efs_file_system_arn         = module.sftp_efs.file_system_arn
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
      module.sftp_efs.file_system_arn
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
