locals {
  ssm_name_prefix          = "/${var.project}/${var.environment}/${var.user_id}"
  ssm_name_user_public_key = "${local.ssm_name_prefix}/SFTP_USER_PUBLIC_KEY"
  ssm_name_username        = "${local.ssm_name_prefix}/SFTP_USERNAME"
}

resource "aws_ssm_parameter" "user_public_key" {
  name        = local.ssm_name_user_public_key
  type        = "SecureString"
  value       = var.public_key
  description = "AWS Transfer Family only accepts PEM formatted public keys. See https://docs.aws.amazon.com/transfer/latest/userguide/key-management.html#convert-ssh2-public-key"
  overwrite   = false

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    UserId      = var.user_id
  }
}

data "aws_ssm_parameter" "user_public_key" {
  name = local.ssm_name_user_public_key
  depends_on = [
    aws_ssm_parameter.user_public_key
  ]
}

resource "aws_ssm_parameter" "sftp_username" {
  name        = local.ssm_name_username
  type        = "SecureString"
  value       = var.username
  description = ""
  overwrite   = false

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    UserId      = var.user_id
  }
}

data "aws_ssm_parameter" "sftp_username" {
  name = local.ssm_name_username
  depends_on = [
    aws_ssm_parameter.sftp_username
  ]
}
