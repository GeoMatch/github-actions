# module "sftp_efs" {
#   source = "../efs"

#   efs_name_prefix   = "-sftp"
#   aws_region        = var.aws_region
#   project           = var.project
#   environment       = var.environment
#   networking_module = var.networking_module
#   ssm_name_prefix   = local.ssm_name_prefix
# }

# resource "aws_efs_mount_target" "this" {
#   file_system_id  = module.sftp_efs.file_system_id
#   subnet_id       = var.networking_module.one_zone_private_subnet_id
#   security_groups = [aws_security_group.efs.id]
# }

# resource "aws_efs_access_point" "this" {
#   file_system_id = module.sftp_efs.file_system_id

#   posix_user {
#     gid = "1000"
#     uid = "1000"
#   }
#   root_directory {
#     path = local.efs_root_directory
#     creation_info {
#       permissions = 755
#       owner_gid   = "1000"
#       owner_uid   = "1000"
#     }
#   }
#   tags = {
#     Project     = var.project
#     Environment = var.environment
#     Name        = "${local.name_prefix}-lambda-ap"
#   }
# }

# resource "aws_security_group" "efs" {
#   name   = "${local.name_prefix}-efs-sg"
#   vpc_id = var.networking_module.vpc_id

#   ingress {
#     description     = "NFS traffic over TCP on port 2049 between the lambda and EFS volume"
#     security_groups = [aws_security_group.lambda.id]
#     from_port       = 2049
#     to_port         = 2049
#     protocol        = "tcp"
#   }

#   tags = {
#     Project     = var.project
#     Environment = var.environment
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_iam_role" "transfer_workflow" {
#   name = "${local.name_prefix}-transfer-workflow"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "transfer.amazonaws.com"
#         }
#       }
#     ]
#   })

#   managed_policy_arns = ["arn:aws:iam::aws:policy/AWSTransferFullAccess"]

#   inline_policy {
#     name = "${var.project}-${var.environment}-transfer-workflow-policy"
#     policy = jsonencode({
#       Version = "2012-10-17"
#       Statement = [
#         {
#           Sid    = "Custom",
#           Effect = "Allow",
#           Action = [
#             "lambda:InvokeFunction"
#           ],
#           Resource = [
#             aws_lambda_function.sftp_to_efs.arn
#           ]
#         },
#       ]
#     })
#   }
# }

# resource "aws_transfer_workflow" "post_upload" {
#   description = "${var.project}-${var.environment}-post-upload-workflow"

#   steps {
#     custom_step_details {
#       name                 = "${var.project}-${var.environment}-copy-to-efs"
#       source_file_location = "$${original.file}"
#       target               = aws_lambda_function.sftp_to_efs.arn
#       timeout_seconds      = 60
#     }
#     type = "CUSTOM"
#   }

#   tags = {
#     Project     = var.project
#     Environment = var.environment
#     Name        = "${var.project}-${var.environment}-post-upload-workflow"
#   }
# }

# resource "aws_transfer_workflow" "post_upload" {
#   description = "Copies files from SFTP S3 to EFS"

#   steps {
#     copy_step_details {
#       name                 = "${var.project}-${var.environment}-copy"
#       source_file_location = "$${original.file}"
#       destination_file_location {
#         efs_file_location {
#           file_system_id = module.sftp_efs.file_system_id
#           path           = "uploads/$${transfer:UserName}/$${transfer:UploadDate}/"
#         }
#       }
#       # overwrite_existing = true
#     }
#     type = "COPY"
#   }

#   tags = {
#     Project     = var.project
#     Environment = var.environment
#   }
# }


