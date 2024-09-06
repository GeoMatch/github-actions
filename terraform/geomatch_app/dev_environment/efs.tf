
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
    # No creation_info to avoid mounting issues:
    # https://repost.aws/knowledge-center/efs-access-point-configurations
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
