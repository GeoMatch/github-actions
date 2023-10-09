locals {
  name_prefix     = "us-global-sftp"
  tag             = "us-global-sftp"
  ssm_name_prefix = "/us-global"
}

resource "aws_security_group" "sftp_us" {
  name   = "${local.name_prefix}-sftp-us-sg"
  vpc_id = aws_vpc.us_global.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Project = local.tag
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip" "sftp_us" {
  tags = {
    Project = local.tag
  }
}

resource "aws_transfer_server" "sftp_us" {
  # Might need force_destroy = true for deleting (or add count to user)
  count                  = var.create_sftp_server ? 1 : 0
  identity_provider_type = "SERVICE_MANAGED"
  logging_role           = aws_iam_role.sftp_us_logging.arn
  protocols              = ["SFTP"]
  domain                 = "S3"
  host_key               = data.aws_ssm_parameter.host_private_key.value
  endpoint_type          = "VPC"
  # I think this creates a VPC endpoint automatically
  endpoint_details {
    vpc_id                 = aws_vpc.us_global.id
    subnet_ids             = [aws_subnet.sftp_us.id]
    security_group_ids     = [aws_security_group.sftp_us.id]
    address_allocation_ids = [aws_eip.sftp_us.id]
  }

  tags = {
    Project = local.tag
  }
}

resource "aws_iam_role" "sftp_us_logging" {
  name = "${local.name_prefix}-logging-role"

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
    name = "${local.name_prefix}-logging-policy"
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

  tags = {
    Project = local.tag
  }
}

resource "aws_transfer_user" "sftp_test" {
  count          = var.create_sftp_server ? 1 : 0
  server_id      = aws_transfer_server.sftp_us[0].id
  role           = aws_iam_role.sftp_us_user.arn
  user_name      = "sftp-test"
  home_directory = "/${aws_s3_bucket.sftp_us.bucket}/sftp-test"

  tags = {
    Project = local.tag
  }
}

resource "aws_transfer_ssh_key" "sftp_test" {
  count     = var.create_sftp_server ? 1 : 0
  server_id = aws_transfer_server.sftp_us[0].id
  user_name = aws_transfer_user.sftp_test[0].user_name
  body      = data.aws_ssm_parameter.test_user_public_key.value
}

resource "aws_iam_role" "sftp_us_user" {
  name = "${local.name_prefix}-user-role"

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
    name = "${local.name_prefix}-user-policy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "s3:ListBucket"
          ],
          "Effect" : "Allow",
          "Resource" : ["${aws_s3_bucket.sftp_us.arn}"]
        },
        {
          # s3:GetObject is not allowed
          "Action" : [
            "s3:PutObject", "s3:DeleteObject"
          ],
          "Effect" : "Allow",
          "Resource" : ["${aws_s3_bucket.sftp_us.arn}/*"]
        },
      ]
    })
  }

  tags = {
    Project = local.tag
  }
}

resource "aws_s3_bucket" "sftp_us" {
  bucket = "${local.name_prefix}-s3-bucket"

  tags = {
    Project = local.tag
  }
}

resource "aws_s3_bucket_ownership_controls" "sftp_us" {
  bucket = aws_s3_bucket.sftp_us.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "stfp_us" {
  bucket = aws_s3_bucket.sftp_us.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.sftp_us]
}

/* -------------------------------------------------------------------------- */
/*                                    Keys                                    */
/* -------------------------------------------------------------------------- */

resource "tls_private_key" "sftp_host_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_private_key" "sftp_test_user_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


locals {
  ssm_name_host_private_key      = "${local.ssm_name_prefix}/SFTP_US_HOST_PRIVATE_KEY"
  ssm_name_host_public_key       = "${local.ssm_name_prefix}/SFTP_US_HOST_PUBLIC_KEY"
  ssm_name_test_user_private_key = "${local.ssm_name_prefix}/SFTP_US_TEST_PRIVATE_KEY"
  ssm_name_test_user_public_key  = "${local.ssm_name_prefix}/SFTP_US_TEST_PUBLIC_KEY"
}

resource "aws_ssm_parameter" "host_private_key" {
  name        = local.ssm_name_host_private_key
  type        = "SecureString"
  value       = tls_private_key.sftp_host_key.private_key_pem
  description = ""
  overwrite   = false

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    Project = local.tag
  }
}

data "aws_ssm_parameter" "host_private_key" {
  name = local.ssm_name_host_private_key
  depends_on = [
    aws_ssm_parameter.host_private_key
  ]
}

resource "aws_ssm_parameter" "host_public_key" {
  name        = local.ssm_name_host_public_key
  type        = "SecureString"
  value       = tls_private_key.sftp_host_key.public_key_openssh
  description = ""
  overwrite   = false

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    Project = local.tag
  }
}

data "aws_ssm_parameter" "host_public_key" {
  name = local.ssm_name_host_public_key
  depends_on = [
    aws_ssm_parameter.host_public_key
  ]
}

resource "aws_ssm_parameter" "test_user_private_key" {
  name        = local.ssm_name_test_user_private_key
  type        = "SecureString"
  value       = tls_private_key.sftp_test_user_key.private_key_pem
  description = ""
  overwrite   = false

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    Project = local.tag
  }
}

data "aws_ssm_parameter" "test_user_private_key" {
  name = local.ssm_name_test_user_private_key
  depends_on = [
    aws_ssm_parameter.test_user_private_key
  ]
}

resource "aws_ssm_parameter" "test_user_public_key" {
  name        = local.ssm_name_test_user_public_key
  type        = "SecureString"
  value       = tls_private_key.sftp_test_user_key.public_key_openssh
  description = ""
  overwrite   = false

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    Project = local.tag
  }
}

data "aws_ssm_parameter" "test_user_public_key" {
  name = local.ssm_name_test_user_public_key
  depends_on = [
    aws_ssm_parameter.test_user_public_key
  ]
}
