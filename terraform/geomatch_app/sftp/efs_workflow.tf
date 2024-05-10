module "sftp_efs" {
  source = "../efs"

  efs_name_prefix   = "-sftp"
  aws_region        = var.aws_region
  project           = var.project
  environment       = var.environment
  networking_module = var.networking_module
  ssm_name_prefix   = local.ssm_name_prefix
}

locals {
  s3_bucket_prefix = "${var.project}-${var.environment}-"
  s3_bucket_suffix = "-sftp"
}

resource "aws_iam_role" "transfer_workflow" {
  name = "${var.project}-${var.environment}-transfer-workflow"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "transfer.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/AWSTransferFullAccess"]

  inline_policy {
    name = "${var.project}-${var.environment}-transfer-workflow-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "s3:GetObject",
            "s3:GetObjectTagging",
            "s3:GetObjectVersionTagging",
            "s3:ListBucket"
          ]
          Effect = "Allow"
          Resource = [
            # Allows read access to all SFTP users buckets
            "arn:aws:s3:::${local.s3_bucket_prefix}*${local.s3_bucket_suffix}",
            "arn:aws:s3:::${local.s3_bucket_prefix}*${local.s3_bucket_suffix}/*",
          ]
        },
        {
          Action = [
            "efs:ClientMount",
            "efs:ClientWrite",
            "efs:ClientRootAccess"
          ]
          Effect   = "Allow"
          Resource = [module.sftp_efs.file_system_arn]
        }
      ]
    })

  }
}

resource "aws_transfer_workflow" "post_upload" {
  description = "Copies files from SFTP S3 to EFS"

  steps {
    copy_step_details {
      name                 = "${var.project}-${var.environment}-copy-s3-to-efs"
      source_file_location = "$${original.file}"
      destination_file_location {
        efs_file_location {
          file_system_id = module.sftp_efs.file_system_id
          path           = "uploads/$${transfer:UserName}/$${transfer:UploadDate}/"
        }
      }
      # overwrite_existing = true
    }
    type = "COPY"
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}


