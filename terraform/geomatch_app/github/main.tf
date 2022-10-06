terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.10"
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

# TODO(refactor): Delete 
resource "aws_iam_role" "github_action_release" {
  name = "${var.project}-${var.environment}-github-action-release-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Principal" : {
          "Federated" : data.aws_iam_openid_connect_provider.github.arn
        },
        "Condition" : {
          "StringLike" : { "token.actions.githubusercontent.com:sub" : "repo:${local.app_repo}:*" }
        }
      }
    ]
  })

  inline_policy {
    name = "release-policy-ecr"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : ["codebuild:StartBuild", "codebuild:BatchGetBuilds"],
          "Resource" : [var.ecr_module.codebuild_project_arn]
        },
        {
          "Effect" : "Allow",
          "Action" : ["logs:GetLogEvents"],
          "Resource" : [
            "${var.ecr_module.codebuild_log_group_arn}:*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : "ssm:PutParameter",
          "Resource" : "*" # TODO
        },
      ]
    })
  }

  dynamic "inline_policy" {
    for_each = var.ecs_module == null ? [] : [1]
    content {
      name = "release-policy-ecs"
      policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Effect" : "Allow",
            "Action" : [
              "ecs:ListServices",
              "ecs:UpdateService",
              "ecs:ListTasks",
              "ecs:RegisterTaskDefinition",
              "ecs:DescribeServices",
              "ecs:DescribeTasks",
              "ecs:ListTaskDefinitions",
              "ecs:DescribeTaskDefinition",
              "ecs:RunTask",
              "ecs:DeregisterTaskDefinition"
            ],
            "Resource" : "*" # TODO(P2)
          },
          {
            "Effect" : "Allow",
            "Action" : [
              "iam:PassRole"
            ],
            "Resource" : [
              var.ecs_module.ecs_task_iam_arn,
              var.ecs_module.ecs_task_execution_iam_arn,
            ]
          }
        ]
      })
    }
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}
