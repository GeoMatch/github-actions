output "alb_dns" {
  value = aws_alb.this.dns_name
}

output "cluster_arn" {
  value = aws_ecs_cluster.this.arn
}

output "task_def_arn" {
  value = aws_ecs_task_definition.this.arn
}

output "ecs_subnet_ids" {
  value = join(",", aws_ecs_service.this.network_configuration[0].subnets)
}

output "ecs_security_groups" {
  value = join(",", aws_ecs_service.this.network_configuration[0].security_groups)
}

output "ecs_task_execution_iam_arn" {
  value = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_iam_arn" {
  value = aws_iam_role.ecs_task.arn
}

output "ecs_cluster_arn" {
  value = aws_ecs_cluster.this.arn
}

output "ssm_ecs_run_task_config_arn" {
  value = aws_ssm_parameter.ecs_run_task_config.arn
}

output "ssm_ecs_run_task_config_name" {
  value = aws_ssm_parameter.ecs_run_task_config.name
}

output "ssm_new_user_password_arn" {
  value = aws_ssm_parameter.new_user_password.arn
}

output "ssm_new_user_password_name" {
  value = aws_ssm_parameter.new_user_password.name
}

output "ecs_service_name" {
  value = aws_ecs_service.this.name
}

output "ecs_task_def_family" {
  value = aws_ecs_task_definition.this.family
}

output "ecs_task_subnet" {
  value = local.one_zone_public_subnet_id
}

output "ecs_task_security_group" {
  value = aws_security_group.app.id
}

output "ssm_geomatch_version_ecs_arn" {
  value = aws_ssm_parameter.geomatch_version_ecs.arn
}

output "app_error_email" {
  value = data.aws_ssm_parameter.django_error_email.value
}

output "app_container_name" {
  value = local.container_name
}
