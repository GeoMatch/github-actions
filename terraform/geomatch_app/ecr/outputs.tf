
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
