
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

resource "aws_iam_role_policy" "efs" {
  name = "${local.name_prefix}-efs-policy"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
        ],
        "Resource" : "*"
        # "Resource" : var.efs_module.file_system_arn,
        "Condition" : {
          "StringEquals" : {
            "elasticfilesystem:AccessPointArn" : values(aws_efs_access_point.this)[*].arn
          }
        }
      }
    ]
  })
}
