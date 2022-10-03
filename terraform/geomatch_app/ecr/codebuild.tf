locals {
  # TODO change this to the version and get from variable
  codebuild_stream_name = "codebuild"
}

resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "${var.cloudwatch_module.log_group_prefix}/codebuild"
  retention_in_days = var.cloudwatch_module.log_group_retention_in_days
  kms_key_id        = var.cloudwatch_module.kms_arn
  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_iam_role" "codebuild" {
  name = "${var.project}-${var.environment}-codebuild-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "codebuild.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name = "codebuild-policy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "ecr:BatchCheckLayerAvailability",
            "ecr:CompleteLayerUpload",
            "ecr:GetAuthorizationToken",
            "ecr:BatchGetImage",
            "ecr:InitiateLayerUpload",
            "ecr:PutImage",
            "ecr:GetDownloadUrlForLayer",
            "ecr:UploadLayerPart"
          ],
          "Resource" : "*",
          "Effect" : "Allow"
        },
        {
          "Effect" : "Allow",
          "Resource" : [
            "*"
          ],
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
        },
      ]
    })
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}


resource "aws_codebuild_project" "app" {
  name                 = "${var.project}-${var.environment}-app-build"
  build_timeout        = "60"
  service_role         = aws_iam_role.codebuild.arn
  resource_access_role = aws_iam_role.codebuild.arn

  source_version = "main"
  source {
    type            = "GITHUB"
    location        = "https://github.com/${local.ssm_val_github_geomatch_app_repo}.git"
    git_clone_depth = 1
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "CONTAINER_URL"
      value = aws_ecr_repository.this.repository_url
    }

    environment_variable {
      name  = "CONTAINER_PORT"
      value = local.ssm_val_container_port_num
    }

    dynamic "environment_variable" {
      for_each = var.codebuild_environment_variables
      content {
        name  = environment_variable.value["name"]
        value = environment_variable.value["value"]
      }
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild.name
    }
  }

  # TODO maybe init docker see priveldged here: https://docs.aws.amazon.com/codebuild/latest/APIReference/API_ProjectEnvironment.html

  #   vpc_config {
  #     vpc_id = aws_vpc.example.id

  #     subnets = [
  #       aws_subnet.example1.id,
  #       aws_subnet.example2.id,
  #     ]

  #     security_group_ids = [
  #       aws_security_group.example1.id,
  #       aws_security_group.example2.id,
  #     ]
  #   }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}
