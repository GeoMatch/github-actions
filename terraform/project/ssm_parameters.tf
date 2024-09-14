locals {
  project             = var.project
  environment         = "global"
  ssm_name_prefix     = "/${var.project}/global"
  ssm_name_repo_owner = "${local.ssm_name_prefix}/GITHUB_REPO_OWNER"
  ssm_name_repo_name  = "${local.ssm_name_prefix}/GITHUB_REPO_NAME"
  ssm_name_repo_pat   = "${local.ssm_name_prefix}/GITHUB_REPO_PAT"
}

resource "aws_ssm_parameter" "repo_owner" {
  name        = local.ssm_name_repo_owner
  type        = "SecureString"
  value       = "GeoMatch"
  description = "GitHub repo owner (i.e. GeoMatch)"

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    Project     = var.project
    Environment = local.environment
  }
}

data "aws_ssm_parameter" "repo_owner" {
  name = local.ssm_name_repo_owner
  depends_on = [
    aws_ssm_parameter.repo_owner
  ]
}

resource "aws_ssm_parameter" "repo_name" {
  name        = local.ssm_name_repo_name
  type        = "SecureString"
  value       = var.repo_name
  description = "i.e. 'us'"

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    Project     = var.project
    Environment = local.environment
  }
}

data "aws_ssm_parameter" "repo_name" {
  name = local.ssm_name_repo_name
  depends_on = [
    aws_ssm_parameter.repo_name
  ]
}

resource "aws_ssm_parameter" "repo_pat" {
  name        = local.ssm_name_repo_pat
  type        = "SecureString"
  value       = "TODO"
  description = "GitHub Personal Access Token (PAT) with repo Contents / Metadata read access"

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    Project     = var.project
    Environment = local.environment
  }
}

data "aws_ssm_parameter" "repo_pat" {
  name = local.ssm_name_repo_pat
  depends_on = [
    aws_ssm_parameter.repo_pat
  ]
}
