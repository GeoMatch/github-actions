output "ssm_repo_name_arn" {
  value = aws_ssm_parameter.repo_name.arn
}

output "ssm_repo_owner_arn" {
  value = aws_ssm_parameter.repo_owner.arn
}

output "ssm_repo_pat_arn" {
  value = aws_ssm_parameter.repo_pat.arn
}
