output "transfer_server_id" {
  value = one(aws_transfer_server.this.id)
}

output "sftp_server_up" {
  value = var.sftp_server_up 
}
