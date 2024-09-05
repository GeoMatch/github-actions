output "transfer_server_id" {
  value = one(aws_transfer_server.this[*].id)
}

output "sftp_server_up" {
  value = var.sftp_server_up
}

# output "lambda_iam_role_id" {
#   value = aws_iam_role.lambda.id
# }

# output "efs_mount_path" {
#   value = local.efs_mount_path
# }

# output "efs_root_directory" {
#   value = local.efs_root_directory
# }

# output "file_system_id" {
#   value = module.sftp_efs.file_system_id
# }
