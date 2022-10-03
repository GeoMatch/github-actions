locals {
  ssm_name_github_geomatch_repo    = "${var.ssm_name_prefix}/GITHUB_GEOMATCH_APP_REPO"
  ssm_val_github_geomatch_app_repo = data.aws_ssm_parameter.github_geomatch_app_repo.value
}

resource "aws_ssm_parameter" "github_geomatch_app_repo" {
  name      = local.ssm_name_github_geomatch_repo
  type      = "String"
  value     = "org/repo-name"
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

data "aws_ssm_parameter" "github_geomatch_app_repo" {
  name = local.ssm_name_github_geomatch_repo
  depends_on = [
    aws_ssm_parameter.github_geomatch_app_repo
  ]
}

locals {
  ssm_name_container_port    = "${var.ssm_name_prefix}/GEOMATCH_APP_CONTAINER_PORT"
  ssm_val_container_port_num = tonumber(data.aws_ssm_parameter.container_port.value)
}

resource "aws_ssm_parameter" "container_port" {
  name      = local.ssm_name_container_port
  type      = "String"
  value     = 8080
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

data "aws_ssm_parameter" "container_port" {
  name = local.ssm_name_container_port
  depends_on = [
    aws_ssm_parameter.container_port
  ]
}
