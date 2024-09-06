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
  name_prefix = "${var.project}-${var.environment}${var.efs_name_prefix}"
  efs_name    = "${local.name_prefix}-efs-elastic"
}

resource "aws_efs_file_system" "this" {
  encrypted              = true # TODO(P2): CMK
  availability_zone_name = var.networking_module.one_zone_az_name
  creation_token         = local.efs_name
  # TODO(P2): Document this decision
  throughput_mode = "elastic"
  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = local.efs_name
  }
}

data "aws_iam_policy_document" "file_system" {
  source_policy_documents = var.extra_fs_policy_documents_json

  # Deny any traffic that isn't secure by default
  statement {
    sid    = "default-deny-unsecured"
    effect = "Deny"
    actions = [
      "*"
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      aws_efs_file_system.this.arn
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_efs_file_system_policy" "this" {
  count          = var.deny_unsecured_traffic ? 1 : 0
  file_system_id = aws_efs_file_system.this.id
  policy         = data.aws_iam_policy_document.file_system.json
}

# TODO(#18): Move mount_target (and its subnet) resources to this module as well.
resource "aws_security_group" "mount_target" {
  name   = "${local.name_prefix}-efs-mt-sg"
  vpc_id = var.networking_module.vpc_id

  ingress {
    description = "NFS traffic over TCP on port 2049 between the resource and EFS volume"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    self        = true
    # We use 'self=true' and output this SG ID so that any consumer
    # of EFS can add this SG to their own resources and access the mount target.
  }

  egress {
    description = "NFS traffic over TCP on port 2049 between the resource and EFS volume"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    self        = true
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_efs_backup_policy" "this" {
  file_system_id = aws_efs_file_system.this.id

  backup_policy {
    status = var.backups_enabled ? "ENABLED" : "DISABLED"
  }
}

/* --------------------------------- Read Replica -------------------------------- */

resource "aws_efs_replication_configuration" "this" {
  count                 = var.read_replica_enabled ? 1 : 0
  source_file_system_id = aws_efs_file_system.this.id

  destination {
    file_system_id         = aws_efs_file_system.replica[0].id
    availability_zone_name = var.networking_module.one_zone_az_name
    region                 = var.aws_region
  }
}

resource "aws_efs_file_system" "replica" {
  count     = var.read_replica_enabled ? 1 : 0
  encrypted = true
  # One AZ cuts down on transfer costs:
  availability_zone_name = var.networking_module.one_zone_az_name
  creation_token         = "${local.efs_name}-replica"
  throughput_mode        = "elastic"

  protection {
    # Needed to be the destination of a replication configuration
    replication_overwrite = "DISABLED"
  }
  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "${local.efs_name}-replica"
  }
}

resource "aws_efs_file_system_policy" "replica" {
  count          = var.read_replica_enabled ? 1 : 0
  file_system_id = aws_efs_file_system.replica[0].id

  # Deny any traffic that isn't secure by default
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Deny",
          "Principal" : {
            "AWS" : "*"
          },
          "Resource" : aws_efs_file_system.replica[0].arn,
          "Action" : "*",
          "Condition" : {
            "Bool" : {
              "aws:SecureTransport" : "false"
            }
          }
        }
      ]
    }
  )
}

resource "aws_security_group" "mount_target_replica" {
  count  = var.read_replica_enabled ? 1 : 0
  name   = "${local.name_prefix}-efs-replica-mt-sg"
  vpc_id = var.networking_module.vpc_id

  ingress {
    description = "NFS traffic over TCP on port 2049 between the lambda and EFS volume"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    self        = true
    # We use 'self=true' and output this SG ID so that any consumer
    # of EFS can add this SG to their own resources and access the mount target.
  }

  egress {
    description = "NFS traffic over TCP on port 2049 between the resource and EFS volume"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    self        = true
  }
  tags = {
    Project     = var.project
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_efs_backup_policy" "replica" {
  count          = var.read_replica_enabled ? 1 : 0
  file_system_id = aws_efs_file_system.replica[0].id

  backup_policy {
    status = "DISABLED"
  }
}
