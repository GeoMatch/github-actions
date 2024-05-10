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

resource "aws_security_group" "this" {
  name   = "${var.project}-${var.environment}-sftp-sg"
  vpc_id = local.vpc_id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    # SFTP tags are different because we resuse
    # resources across environments.
    Project     = var.project
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip" "this" {
  # We never turn down elastic IP so we can keep it associated
  # with our account.
  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "sftp_server" {
  name_prefix = "${var.project}-${var.environment}-sftp-"
}

resource "aws_transfer_server" "this" {
  # Might need force_destroy = true for deleting (or add count to user)
  count                  = var.sftp_server_up ? 1 : 0
  identity_provider_type = "SERVICE_MANAGED"
  logging_role           = aws_iam_role.sftp_logging.arn
  protocols              = ["SFTP"]
  domain                 = "S3"
  host_key               = data.aws_ssm_parameter.host_private_key.value
  structured_log_destinations = [
    "${aws_cloudwatch_log_group.sftp_server.arn}:*"
  ]
  endpoint_type = "VPC"
  # I think this creates a VPC endpoint automatically
  endpoint_details {
    vpc_id                 = var.networking_module.vpc_id
    subnet_ids             = [var.networking_module.one_zone_public_subnet_id]
    security_group_ids     = [aws_security_group.this.id]
    address_allocation_ids = [aws_eip.this.id]
  }

  # TODO(#10): Add lambda to write to EFS 
  # workflow_details {
    # on_upload {
    #   execution_role = aws_iam_role.transfer_workflow.arn
    #   workflow_id    = aws_transfer_workflow.post_upload.id
    # }
  # }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_iam_role" "sftp_logging" {
  name = "${var.project}-${var.environment}-sftp-logging-role"

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
    name = "${var.project}-sftp-logging-policy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : ["logs:CreateLogStream", "logs:CreateLogGroup", "logs:PutLogEvents"],
          "Effect" : "Allow",
          "Resource" : "*"
        }
      ]
    })
  }

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"]

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "tls_private_key" "host" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
