locals {
  ssm_name_prefix           = "/${var.project}"
  ssm_name_host_private_key = "${local.ssm_name_prefix}/SFTP_HOST_PRIVATE_KEY"
  ssm_name_host_public_key  = "${local.ssm_name_prefix}/SFTP_HOST_PUBLIC_KEY"
}

resource "aws_ssm_parameter" "host_private_key" {
  name        = local.ssm_name_host_private_key
  type        = "SecureString"
  value       = tls_private_key.host.private_key_pem
  description = ""
  overwrite   = false

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    Project = var.project
  }
}

data "aws_ssm_parameter" "host_private_key" {
  name = local.ssm_name_host_private_key
  depends_on = [
    aws_ssm_parameter.host_private_key
  ]
}

resource "aws_ssm_parameter" "host_public_key" {
  name        = local.ssm_name_host_public_key
  type        = "SecureString"
  value       = tls_private_key.host.public_key_openssh
  description = ""
  overwrite   = false

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    Project = var.project
  }
}

data "aws_ssm_parameter" "host_public_key" {
  name = local.ssm_name_host_public_key
  depends_on = [
    aws_ssm_parameter.host_public_key
  ]
}
