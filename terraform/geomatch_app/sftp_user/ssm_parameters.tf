locals {
  ssm_name_prefix                  = "/${var.project}"
  # TODO(refactor)
  ssm_name_user_public_key    = "${local.ssm_name_prefix}/SFTP_${upper(var.environment)}_USER_PUBLIC_KEY"
  ssm_name_username           = "${local.ssm_name_prefix}/SFTP_${upper(var.environment)}_USERNAME"
}

resource "aws_ssm_parameter" "user_public_key" {
  name        = local.ssm_name_user_public_key
  type        = "SecureString"
  value       = "placeholder"
  description = "AWS Transfer Family only accepts PEM formatted public keys. See https://docs.aws.amazon.com/transfer/latest/userguide/key-management.html#convert-ssh2-public-key"
  overwrite   = false

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    # TODO(refactor): Add environment
    Project = var.project
  }
}

data "aws_ssm_parameter" "user_public_key" {
  name = local.ssm_name_user_public_key
  depends_on = [
    aws_ssm_parameter.prod_user_public_key
  ]
}

resource "aws_ssm_parameter" "sftp_username" {
  name        = local.ssm_name_username
  type        = "SecureString"
  value       = "prod-username"
  description = ""
  overwrite   = false

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    # TODO(refactor): Add environment
    Project = var.project
  }
}

data "aws_ssm_parameter" "sftp_username" {
  name = local.ssm_name_username
  depends_on = [
    aws_ssm_parameter.sftp_username
  ]
}
