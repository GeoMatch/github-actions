output "transfer_server_id" {
  value = one(aws_transfer_server.this[*].id)
}

output "sftp_server_up" {
  value = var.sftp_server_up
}

output "s3_bucket_prefix" {
  value = local.s3_bucket_prefix
}

output "s3_bucket_suffix" {
  value = local.s3_bucket_prefix
}
