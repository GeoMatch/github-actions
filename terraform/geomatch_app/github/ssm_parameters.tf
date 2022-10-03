locals {
  ssm_name_github_tf_provider_token = "${var.ssm_name_prefix}/GITHUB_TF_PROVIDER_TOKEN"
  ssm_val_github_tf_provider_token  = data.aws_ssm_parameter.github_tf_provider_token.value
}

resource "aws_ssm_parameter" "github_tf_provider_token" {
  name      = local.ssm_name_github_tf_provider_token
  type      = "SecureString"
  value     = "token"
  overwrite = false

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

data "aws_ssm_parameter" "github_tf_provider_token" {
  name = local.ssm_name_github_tf_provider_token
  depends_on = [
    aws_ssm_parameter.github_tf_provider_token
  ]
}
