terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.42"
    }
  }

  required_version = ">= 1.1.8"
}

locals {
  vpc_id = var.networking_module.vpc_id
}

resource "aws_security_group" "this" {
  name   = "${var.project}-sftp-sg"
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
    Project = var.project
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip" "this" {
  # We never turn down elastic IP so we can keep it associated
  # with our account.
  tags = {
    Project = var.project
  }
}

resource "aws_cloudwatch_log_group" "sftp_server" {
  name_prefix = "${var.project}-sftp-"
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

  tags = {
    Project = var.project
  }
}

resource "aws_iam_role" "sftp_prod_user" {
  name = "${var.project}-prod-sftp-user-role"

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
    name = "${var.project}-prod-sftp-user-policy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "s3:ListBucket"
          ],
          "Effect" : "Allow",
          "Resource" : ["${aws_s3_bucket.sftp_prod.arn}"]
        },
        {
          # s3:GetObject is not allowed
          "Action" : [
            "s3:PutObject", "s3:DeleteObject"
          ],
          "Effect" : "Allow",
          "Resource" : ["${aws_s3_bucket.sftp_prod.arn}/*"]
        },
      ]
    })
  }

  tags = {
    Project     = var.project
    Environment = "prod"
  }
}

resource "aws_iam_role" "sftp_staging_user" {
  name = "${var.project}-staging-sftp-user-role"

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
    name = "${var.project}-staging-sftp-user-policy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "s3:ListBucket"
          ],
          "Effect" : "Allow",
          "Resource" : ["${aws_s3_bucket.sftp_staging.arn}"]
        },
        {
          # s3:GetObject is not allowed
          "Action" : [
            "s3:PutObject", "s3:DeleteObject"
          ],
          "Effect" : "Allow",
          "Resource" : ["${aws_s3_bucket.sftp_staging.arn}/*"]
        },
      ]
    })
  }

  tags = {
    Project     = var.project
    Environment = "staging"
  }
}


resource "aws_iam_role" "sftp_logging" {
  name = "${var.project}-sftp-logging-role"

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
    Project = var.project
  }
}

resource "aws_transfer_user" "sftp_prod" {
  count          = var.sftp_server_up ? 1 : 0
  server_id      = aws_transfer_server.this[0].id
  role           = aws_iam_role.sftp_prod_user.arn
  user_name      = data.aws_ssm_parameter.prod_sftp_username.value
  home_directory = "/${aws_s3_bucket.sftp_prod.bucket}"

  tags = {
    Project     = var.project
    Environment = "prod"
  }
}

resource "aws_transfer_user" "sftp_staging" {
  count          = var.sftp_server_up ? 1 : 0
  server_id      = aws_transfer_server.this[0].id
  role           = aws_iam_role.sftp_staging_user.arn
  user_name      = data.aws_ssm_parameter.staging_sftp_username.value
  home_directory = "/${aws_s3_bucket.sftp_staging.bucket}"

  tags = {
    Project     = var.project
    Environment = "staging"
  }
}

resource "aws_transfer_ssh_key" "sftp_prod" {
  count     = var.sftp_server_up ? 1 : 0
  server_id = aws_transfer_server.this[0].id
  user_name = aws_transfer_user.sftp_prod[0].user_name
  body      = data.aws_ssm_parameter.prod_user_public_key.value
}

resource "aws_transfer_ssh_key" "sftp_staging" {
  count     = var.sftp_server_up ? 1 : 0
  server_id = aws_transfer_server.this[0].id
  user_name = aws_transfer_user.sftp_staging[0].user_name
  body      = data.aws_ssm_parameter.staging_user_public_key.value
}

resource "aws_s3_bucket" "sftp_prod" {
  bucket = "${var.project}-prod-sftp"

  tags = {
    Project     = var.project
    Environment = "prod"
  }
}

resource "aws_s3_bucket" "sftp_staging" {
  bucket = "${var.project}-staging-sftp"

  tags = {
    Project     = var.project
    Environment = "staging"
  }
}

resource "aws_s3_bucket_ownership_controls" "sftp_prod" {
  bucket = aws_s3_bucket.sftp_prod.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_ownership_controls" "sftp_staging" {
  bucket = aws_s3_bucket.sftp_staging.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "stfp_prod" {
  bucket = aws_s3_bucket.sftp_prod.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.sftp_prod]
}

resource "aws_s3_bucket_acl" "stfp_staging" {
  bucket = aws_s3_bucket.sftp_staging.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.sftp_staging]
}

resource "aws_s3_bucket_versioning" "sftp_prod" {
  bucket = aws_s3_bucket.sftp_prod.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "sftp_staging" {
  bucket = aws_s3_bucket.sftp_staging.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "tls_private_key" "host" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
