locals {
  # ECS task is in public subnet, but cross-subnet in one AZ is fine
  efs_mount_target_subnet_id = var.networking_module.one_zone_private_subnet_id
  efs_access_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite"
        ],
        "Resource" : var.efs_module.file_system_arn,
        "Condition" : {
          "StringEquals" : {
            "elasticfilesystem:AccessPointArn" : aws_efs_access_point.this.arn
          }
        }
      }
    ]
  })
}

# See the following for a discussion of access point permissioning:
# https://aws.amazon.com/blogs/containers/developers-guide-to-using-amazon-efs-with-amazon-ecs-and-aws-fargate-part-2/
resource "aws_efs_access_point" "this" {
  file_system_id = var.efs_module.file_system_id
  # Any client using this AP will act as the following user:
  posix_user {
    gid = "1000"
    uid = "1000"
  }
  root_directory {
    path = "/${var.project}-${var.environment}-appdata"
    creation_info {
      permissions = 755
      owner_gid   = "1000"
      owner_uid   = "1000"
    }
  }
  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_security_group" "efs" {
  name   = "${var.project}-${var.environment}-efs-sg"
  vpc_id = local.vpc_id

  tags = {
    Project     = var.project
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_efs" {
  security_group_id            = aws_security_group.efs.id
  description                  = "NFS traffic over TCP on port 2049 between the app and EFS volume"
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "${var.project}-${var.environment}-app-efs"
  }
}

resource "aws_vpc_security_group_ingress_rule" "lambda_efs" {
  security_group_id            = aws_security_group.efs.id
  description                  = "NFS traffic over TCP on port 2049 between the lambda and EFS volume"
  referenced_security_group_id = aws_security_group.r_lambda.id
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "${var.project}-${var.environment}-lambda-efs"
  }
}

resource "aws_efs_mount_target" "this" {
  file_system_id  = var.efs_module.file_system_id
  subnet_id       = local.efs_mount_target_subnet_id
  security_groups = [aws_security_group.efs.id]
}
