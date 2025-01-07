variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "ecr_name_suffix" {
  type    = string
  default = "app"
}

variable "ssm_name_prefix" {
  type        = string
  description = "should be '/{project}/{environment}'"
}

// Cognito variables for the user pool in a given region and environment
variable "cognito_region" {
  description = "The region where the user pool is created"
  type = string
}

variable "cognito_client_id" {
  description = "The client ID of the user pool"
  type = string
}

variable "cognito_user_pool_id" {
  description = "The ID of the user pool"
  type = string
}

variable "cognito_client_secret" {  
  description = "The client secret of the user pool"
  type = string
}

variable "cognito_redirect_uri" {
  description = "The redirect URI of the user pool"
  type = string
}

variable "cognito_app_domain" {
  description = "The domain of the user pool"
  type = string
}

variable "cognito_authorization_endpoint" {
  description = "The authorization endpoint of the user pool"
  type = string
}

variable "cognito_allow_domain" {
  description = "The CORS domain allowed for the user pool"
  type = string
}

// Cognito variables for the user pool in a given region and environment
variable "cognito_email_verification_message" {
  type = string
}

variable "cognito_email_verification_subject" {
  type = string
}

variable "cognito_admin_create_user_message" {
  type = string
}

variable "cognito_admin_create_user_subject" {
  type = string
}

variable "cognito_allow_email_address" {
  type = string
}