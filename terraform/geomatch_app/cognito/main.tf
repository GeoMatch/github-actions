terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }

    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
  }

  required_version = ">= 1.1.8"
}

resource "aws_cognito_user_pool" "this" {
  name = "${var.project}-${var.environment}-cognito"
  mfa_configuration = "ON"

  software_token_mfa_configuration {
    enabled = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "admin_only"
      priority = 1
    }
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
    invite_message_template {
      email_message = "Welcome to GeoMatch! Your username is {username} and temporary password is {####}"
      email_subject = "GeoMatch Account Invitation"
    }
  }

  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
  }

  username_configuration {
    case_sensitive = false
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_message = "Your verification code is {####}"
    email_subject = "Your verification code"
  }

  schema {
    name = "email"
    attribute_data_type = "String"
    required = true
    mutable = true
    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }
  
  tags = {
    Terraform = true
    Environment = var.environment
  }
}

resource "aws_cognito_user_pool_client" "this" {
  name = "${var.project}-${var.environment}-cognito-client"
  user_pool_id = aws_cognito_user_pool.this.id
  generate_secret = true
  callback_urls = [var.cognito_redirect_uri]
  logout_urls = [var.cognito_redirect_uri]
  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = ["email", "openid"]
  allowed_oauth_flows_user_pool_client = true
}

resource "aws_cognito_user_pool_domain" "this" {
  domain = "${var.project}-${var.environment}-cognito"
  user_pool_id = aws_cognito_user_pool.this.id
}
