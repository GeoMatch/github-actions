
#output "geomatch_app_container_port" {
#  value = local.ssm_val_container_port_num
#}

#output "geomatch_app_ecr_repo_arn" {
#  value = aws_ecr_repository.this.arn
#}

#output "geomatch_app_ecr_repo_url" {
#  sensitive = true
#  value     = aws_ecr_repository.this.repository_url
#}

#output "geomatch_app_ecr_repo_name" {
#  value = aws_ecr_repository.this.name
#}

output "cognito_region" {
  description = "The AWS region where Cognito resources are created"
  value       = var.aws_region  # or however you define your region
}

output "cognito_client_id" {
  description = "The Cognito User Pool Client ID"
  value       = aws_cognito_user_pool_client.client.id
}

output "cognito_user_pool_id" {
  description = "The Cognito User Pool ID"
  value       = aws_cognito_user_pool.pool.id
}

# Add other required outputs
output "cognito_client_secret" {
  description = "The Cognito User Pool Client Secret"
  value       = aws_cognito_user_pool_client.client.client_secret
  sensitive   = true
}

output "cognito_redirect_uri" {
  description = "The Cognito redirect URI"
  value       = var.redirect_uri
}

output "cognito_app_domain" {
  description = "The Cognito app domain"
  value       = aws_cognito_user_pool_domain.main.domain
}

output "cognito_authorization_endpoint" {
  description = "The Cognito authorization endpoint"
  value       = "${aws_cognito_user_pool.pool.endpoint}/oauth2/authorize"
}

output "cognito_allow_domain" {
  description = "The allowed domain for Cognito"
  value       = var.allow_domain
}
