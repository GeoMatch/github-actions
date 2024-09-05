output "file_system_id" {
  value = aws_efs_file_system.this.id
}

output "file_system_arn" {
  value = aws_efs_file_system.this.arn
}

output "mount_target_sg_id" {
  description = "Add this security group to your resources to receive access to the EFS's mount target."
  value       = aws_security_group.mount_target.id
}

output "read_replica_file_system_id" {
  value = var.read_replica_enabled ? aws_efs_file_system.replica[0].id : null
}

output "read_replica_file_system_arn" {
  value = var.read_replica_enabled ? aws_efs_file_system.replica[0].arn : null
}

output "read_replica_mount_target_sg_id" {
  description = "Add this security group to your resources to receive access to the EFS's mount target."
  value       = aws_security_group.mount_target.id
}
