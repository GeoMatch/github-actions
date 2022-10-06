locals {
  ssm_name_container_port    = "${var.ssm_name_prefix}/GEOMATCH_APP_CONTAINER_PORT"
  ssm_val_container_port_num = tonumber(data.aws_ssm_parameter.container_port.value)
}

# This is in ECR module because it's a hard coded build variable
# to Docker (as a build arg) 
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
