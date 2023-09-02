locals {
  r_lambda_name         = "${var.project}-${var.environment}-r-lambda"
  lambda_efs_mount_path = "/mnt/efs"
  lambda_access_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "lambda:InvokeFunction"
        ],
        Effect   = "Allow",
        Resource = aws_lambda_function.r_lambda.arn
      }
    ]
  })
}

resource "aws_security_group" "r_lambda" {
  name   = "${var.project}-${var.environment}-lambda-sg"
  vpc_id = local.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lambda_function" "r_lambda" {
  function_name = local.r_lambda_name
  role          = aws_iam_role.r_lambda_exec.arn
  image_uri     = local.gm_container_url
  package_type  = "Image"
  timeout       = 60 * 4

  image_config {
    command = ["api.core.aws_lambda.r"]
  }

  file_system_config {
    arn              = aws_efs_access_point.this.arn
    local_mount_path = local.lambda_efs_mount_path
  }

  environment {
    # Ideally, we would use the same mount path.
    # However, the app mount was prefixed with /data/
    # before I knew lambda required mounts to start with /mnt/
    variables = {
      APP_EFS_DIR    = local.lambda_efs_mount_path
      LAMBDA_EFS_DIR = local.app_efs_container_mount_path
    }
  }

  vpc_config {
    # Every subnet should be able to reach an EFS mount target in the same Availability Zone. Cross-AZ mounts are not permitted.
    subnet_ids         = [local.efs_mount_target_subnet_id]
    security_group_ids = [aws_security_group.r_lambda.id]
  }

  # When creating or updating Lambda functions, mount target must be in 'available' lifecycle state.
  depends_on = [aws_efs_mount_target.this]

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}


resource "aws_iam_role" "r_lambda_exec" {
  name = "${var.project}-${var.environment}-r-lambda-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name   = "efs_policy"
    policy = local.efs_access_policy
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}
