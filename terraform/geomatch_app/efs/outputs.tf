output "file_system_id" {
  value = aws_efs_file_system.this.id
}

output "file_system_arn" {
  value = aws_efs_file_system.this.arn
}

output "read_replica_file_system_id" {
  value = var.read_replica_enabled ? aws_efs_file_system.replica[0].id : null
}

output "read_replica_file_system_arn" {
  value = var.read_replica_enabled ? aws_efs_file_system.replica[0].arn : null
}
