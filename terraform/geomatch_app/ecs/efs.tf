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

  ingress {
    protocol        = "tcp"
    from_port       = 2049
    to_port         = 2049
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.app.id]
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_efs_mount_target" "this" {
  file_system_id = var.efs_module.file_system_id
  # ECS task is in public subnet, but cross-subnet in one AZ is fine
  subnet_id       = var.networking_module.one_zone_private_subnet_id
  security_groups = [aws_security_group.efs.id]
}
