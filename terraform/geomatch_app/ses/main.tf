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

resource "aws_iam_user" "ses_smtp" {
  name = "${var.project}-${var.environment}-ses-smtp-user"

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_iam_access_key" "ses_smtp" {
  user = aws_iam_user.ses_smtp.name
}

resource "aws_iam_user_policy" "ses_smtp" {
  name = "${var.project}-${var.environment}-ses-smtp-user-policy"
  user = aws_iam_user.ses_smtp.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        // Could probably fetch this arn via 'data' instead.
        Resource = "arn:aws:ses:us-east-1:${data.aws_caller_identity.current.account_id}:identity/${var.sender_domain}",
        Action   = "ses:SendRawEmail",
      }
    ]
  })
}
