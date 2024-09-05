# data "archive_file" "lambda" {
#   type        = "zip"
#   source_dir  = "${path.module}/lambda_source/"
#   output_path = "${path.module}/lambda_function.zip"
# }

# locals {
#   lambda_name        = "${var.project}-${var.environment}-sftp-copy-efs"
#   efs_root_directory = "/data"
#   efs_mount_path     = "/data"
# }

# resource "aws_lambda_function" "sftp_to_efs" {
#   function_name = local.lambda_name
#   runtime       = "python3.11"
#   handler       = "sftp_copy.handler"
#   role          = aws_iam_role.lambda.arn

#   filename   = data.archive_file.lambda.output_path
#   depends_on = [data.archive_file.lambda]

#   file_system_config {
#     arn              = aws_efs_access_point.this.arn
#     local_mount_path = local.efs_mount_path
#   }

#   vpc_config {
#     security_group_ids = [aws_security_group.lambda.id]
#     subnet_ids         = [var.networking_module.one_zone_public_subnet_id]
#   }

#   environment {
#     variables = {
#       PROJECT     = var.project
#       ENVIRONMENT = var.environment
#       MOUNT_PATH  = local.efs_mount_path
#     }
#   }

#   tags = {
#     Project     = var.project
#     Environment = var.environment
#   }
# }

# resource "aws_iam_role" "lambda" {
#   name = "${var.project}-${var.environment}-lambda-sftp-copy"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "lambda.amazonaws.com"
#         }
#       },
#     ]
#   })

#   managed_policy_arns = [
#     "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
#   ]

#   tags = {
#     Project     = var.project
#     Environment = var.environment
#   }
# }

# resource "aws_iam_role_policy" "lambda_efs" {
#   name = "${local.name_prefix}-lambda-efs-policy"
#   role = aws_iam_role.lambda.id

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Action = [
#           "efs:ClientMount",
#           "efs:ClientWrite",
#           "efs:ClientRootAccess"
#         ]
#         Effect   = "Allow"
#         Resource = [module.sftp_efs.file_system_arn],
#         Condition = {
#           StringEquals = {
#             "elasticfilesystem:AccessPointArn" = aws_efs_access_point.this.arn
#           }
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy" "lambda_cloudwatch" {
#   name = "${local.name_prefix}-lambda-cloudwatch-policy"
#   role = aws_iam_role.lambda.id

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect   = "Allow",
#         Action   = "logs:CreateLogGroup",
#         Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
#       },
#       {
#         Effect = "Allow",
#         Action = [
#           "logs:CreateLogStream",
#           "logs:PutLogEvents"
#         ],
#         Resource = [
#           "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.lambda_name}:*"
#         ]
#       }
#     ]
#   })
# }

# resource "aws_security_group" "lambda" {
#   name   = "${local.name_prefix}-lambda-sg"
#   vpc_id = var.networking_module.vpc_id

#   egress {
#     description      = "Allow all outbound"
#     from_port        = 0
#     to_port          = 0
#     protocol         = "-1"
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }

#   tags = {
#     Project     = var.project
#     Environment = var.environment
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }
