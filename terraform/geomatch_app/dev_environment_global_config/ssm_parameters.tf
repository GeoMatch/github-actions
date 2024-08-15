locals {
  project         = "global"
  ssm_name_prefix = "/${local.project}"
  ssm_name_users  = "${local.ssm_name_prefix}/CLOUD_ENVIRONMENT_USERS"
}

resource "aws_ssm_parameter" "users" {
  name        = local.ssm_name_users
  type        = "SecureString"
  value       = "TODO"
  description = "Linux users in the form: 'username1:password1;username2:password2'"
  # Note: Trying to remove overwrite=false here. Might cause problems, but I think not

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    Project = local.project
  }
}

data "aws_ssm_parameter" "users" {
  name = local.ssm_name_users
  depends_on = [
    aws_ssm_parameter.users
  ]
}
