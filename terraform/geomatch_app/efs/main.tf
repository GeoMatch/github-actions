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
  efs_name = "${var.project}-${var.environment}${var.efs_name_prefix}-efs-elastic"
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

resource "aws_efs_file_system_policy" "this" {
  count          = var.deny_unsecured_traffic ? 1 : 0
  file_system_id = aws_efs_file_system.this.id

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
          "Resource" : aws_efs_file_system.this.arn,
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

resource "aws_efs_backup_policy" "replica" {
  count          = var.read_replica_enabled ? 1 : 0
  file_system_id = aws_efs_file_system.replica[0].id

  backup_policy {
    status = "DISABLED"
  }
}
