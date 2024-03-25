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

resource "aws_ecr_repository" "this" {
  name                 = "${var.project}-${var.environment}-app"
  image_tag_mutability = "MUTABLE"

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

# Don't keep more than 10 versions of an image
resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep last 10 images"
      action = {
        type = "expire"
      }
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 30
      }
    }]
  })
}
