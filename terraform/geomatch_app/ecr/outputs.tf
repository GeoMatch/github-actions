
output "geomatch_app_container_port" {
  value = local.ssm_val_container_port_num
}

output "geomatch_app_ecr_repo_arn" {
  value = aws_ecr_repository.this.arn
}

output "geomatch_app_ecr_repo_url" {
  sensitive = true
  value     = aws_ecr_repository.this.repository_url
}

output "geomatch_app_ecr_repo_name" {
  value = aws_ecr_repository.this.name
}

output "github_geomatch_app_repo" {
  value = data.aws_ssm_parameter.github_geomatch_app_repo.value
}


output "codebuild_project_arn" {
  value = aws_codebuild_project.app.arn
}

output "codebuild_project_name" {
  value = aws_codebuild_project.app.name
}

output "codebuild_log_group_arn" {
  value = aws_cloudwatch_log_group.codebuild.arn
}
