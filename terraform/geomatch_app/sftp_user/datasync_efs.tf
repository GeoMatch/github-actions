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
}

resource "aws_efs_mount_target" "this" {
  file_system_id  = module.sftp_efs.file_system_id
  subnet_id       = var.networking_module.one_zone_private_subnet_id
  security_groups = [module.sftp_efs.mount_target_sg_id]
}

resource "aws_efs_access_point" "this" {
  file_system_id = module.sftp_efs.file_system_id

  # Creates read-only access point for DataSync
  posix_user {
    # TODO: Might need root here and below?
    gid = "datasync"
    uid = "datasync"
  }

  root_directory {
    path = "/"
    creation_info {
      permissions = 755 # Read/write for datasync. Read-only for others
      owner_gid   = "datasync"
      owner_uid   = "datasync"
    }
  }
  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "${local.name_prefix}-efs-ap"
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
