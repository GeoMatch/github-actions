
resource "aws_efs_access_point" "this" {
  for_each = var.efs_configs

  file_system_id = each.value.file_system_id
  # Any client using this AP will act as logged-in user 
  root_directory {
    path = each.value.root_directory
    # https://repost.aws/knowledge-center/efs-access-point-configurations
    creation_info {
      permissions = 755
      owner_gid   = "0"
      owner_uid   = "0"
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
