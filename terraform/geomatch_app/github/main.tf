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


locals {
  app_repo   = var.github_geomatch_app_repo
  repo_owner = split("/", local.app_repo)[0]
  repo_name  = split("/", local.app_repo)[1]
}

provider "github" {
  token = local.ssm_val_github_tf_provider_token
  owner = local.repo_owner
}

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}
