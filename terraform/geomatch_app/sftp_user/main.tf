terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
  }

  required_version = ">= 1.1.8"
}

locals {
  vpc_id = var.networking_module.vpc_id
}

resource "aws_iam_role" "sftp_user" {
  name = "${var.project}-${var.environment}-${var.user_id}-sftp-user-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "transfer.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name = "${var.project}-${var.environment}-${var.user_id}-sftp-user-policy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "s3:ListBucket"
          ],
          "Effect" : "Allow",
          "Resource" : ["${aws_s3_bucket.this.arn}"]
        },
        {
          # s3:GetObject is not allowed
          "Action" : [
            "s3:PutObject", "s3:DeleteObject"
          ],
          "Effect" : "Allow",
          "Resource" : ["${aws_s3_bucket.this.arn}/*"]
        },
      ]
    })
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    UserId      = var.user_id
  }
}

resource "aws_transfer_user" "this" {
  count          = var.sftp_module.sftp_server_up ? 1 : 0
  server_id      = var.sftp_module.transfer_server_id
  role           = aws_iam_role.sftp_user.arn
  user_name      = data.aws_ssm_parameter.sftp_username.value
  home_directory = "/${aws_s3_bucket.this.bucket}"

  tags = {
    Project     = var.project
    Environment = var.environment
    UserId      = var.user_id
  }
}

resource "aws_transfer_ssh_key" "this" {
  count     = var.sftp_module.sftp_server_up ? 1 : 0
  server_id = var.sftp_module.transfer_server_id
  user_name = aws_transfer_user.this[0].user_name
  body      = data.aws_ssm_parameter.user_public_key.value
}

resource "aws_s3_bucket" "this" {
  bucket = "${var.sftp_module.s3_bucket_prefix}${var.user_id}${var.sftp_module.s3_bucket_suffix}"

  tags = {
    Project     = var.project
    Environment = var.environment
    UserId      = var.user_id
  }
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.this.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.this]
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}
