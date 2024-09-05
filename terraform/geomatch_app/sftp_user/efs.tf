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
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "this" {
  file_system_id = module.sftp_efs.file_system_id

  posix_user {
    gid = "1000"
    uid = "1000"
  }
  root_directory {
    path = "/"
    creation_info {
      permissions = 755
      owner_gid   = "1000"
      owner_uid   = "1000"
    }
  }
  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "${local.name_prefix}-lambda-ap"
  }
}

resource "aws_security_group" "efs" {
  name   = "${local.name_prefix}-efs-sg"
  vpc_id = var.networking_module.vpc_id

  ingress {
    description = "NFS traffic over TCP on port 2049 between the lambda and EFS volume"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    # Also used for datasync so we include self
    self = true
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    UserId      = var.user_id
  }

  lifecycle {
    create_before_destroy = true
  }
}
