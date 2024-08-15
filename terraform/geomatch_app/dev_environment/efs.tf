
resource "aws_efs_mount_target" "this" {
  for_each = var.efs_configs

  file_system_id  = each.value.file_system_id
  subnet_id       = aws_subnet.ecs.id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "this" {
  for_each = var.efs_configs

  file_system_id = each.value.file_system_id
  # Any client using this AP will act as the following user:
  posix_user {
    gid = "1000"
    uid = "1000"
  }
  root_directory {
    path = each.value.root_directory
    creation_info {
      permissions = each.value.read_only ? 555 : 755
      owner_gid   = "1000"
      owner_uid   = "1000"
    }
  }
  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "${local.name_prefix}-${each.value.volume_name}"
    # These are to make looping over access points in ECS task def easier:
    VolumeName = each.value.volume_name
    MountPath  = each.value.mount_path
    ReadOnly   = each.value.read_only
  }
}

resource "aws_security_group" "efs" {
  name   = "${local.name_prefix}-efs-sg"
  vpc_id = var.networking_module.vpc_id

  ingress {
    description     = "NFS traffic over TCP on port 2049 between the app and EFS volume"
    security_groups = [aws_security_group.ecs.id]
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}
