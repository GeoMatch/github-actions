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
  timeout       = 60 * 8
  memory_size   = 1024 * 9

  image_config {
    command = ["python", "-m", "awslambdaric", "api.core.aws_lambda.r.lambda_handler"]
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
      LAMBDA_EFS_DIR     = local.lambda_efs_mount_path
      APP_EFS_DIR        = local.app_efs_container_mount_path
      GEOMATCH_VERSION   = var.geomatch_version
      RENV_PATHS_LIBRARY = "renv/library"
      # Lambda home dir isn't writable.
      # Fix: turned off cache entirely
      # RENV_PATHS_ROOT    = "${local.lambda_efs_mount_path}/.cache/R/renv"
      # RENV_PATHS_SANDBOX = "${local.lambda_efs_mount_path}/.cache/R/renv/sandbox"
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

  inline_policy {
    name = "cloudwatch"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          "Effect" : "Allow",
          "Action" : "logs:CreateLogGroup",
          "Resource" : "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
        },

        {
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource" : [
            "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.r_lambda_name}:*"
          ]
        }
      ]
    })
  }

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  ]

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

# AWS added this automatically, but may have to add it in the future
#
# resource "aws_ecr_repository_policy" "my_repository_policy" {
#   repository = aws_ecr_repository.my_repository.name

#   policy = jsonencode({
#     Version = "2008-10-17"
#     Statement = [
#       {
#         Sid    = "LambdaECRImageRetrievalPolicy"
#         Effect = "Allow"
#         Principal = {
#           Service = "lambda.amazonaws.com"
#         }
#         Action = [
#           "ecr:BatchCheckLayerAvailability",
#           "ecr:GetDownloadUrlForLayer",
#         ]
#       }
#     ]
#   })
# }
