
resource "aws_efs_access_point" "this" {
  for_each = var.efs_configs

  file_system_id = each.value.file_system_id

  dynamic "posix_user" {
    for_each = each.value.ap_user_uid_gid_number != "" ? [1] : []
    content {
      uid = each.value.ap_user_uid_gid_number
      gid = each.value.ap_user_uid_gid_number
    }
  }

  # https://repost.aws/knowledge-center/efs-access-point-configurations
  root_directory {
    path = each.value.root_directory
    dynamic "creation_info" {
      for_each = each.value.root_dir_creator_uid_gid_number != "" ? [1] : []
      content {
        permissions = each.value.root_dir_creation_posix_permissions
        owner_gid   = each.value.root_dir_creator_uid_gid_number
        owner_uid   = each.value.root_dir_creator_uid_gid_number
      }
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
    RootAccess = each.value.root_access
  }
}

resource "aws_iam_role_policy" "efs" {
  for_each = aws_efs_access_point.this

  name = "${local.name_prefix}-efs-policy-${each.value.tags["VolumeName"]}"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : concat([
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          ],
          lower(each.value.tags["RootAccess"]) == "true" ?
        ["elasticfilesystem:ClientRootAccess"] : []),
        "Resource" : "*"
        # "Resource" : var.efs_module.file_system_arn,
        "Condition" : {
          "StringEquals" : {
            "elasticfilesystem:AccessPointArn" : each.value.arn
          }
        }
      }
    ]
  })
}
