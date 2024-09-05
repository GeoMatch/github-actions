output "file_system_id" {
  value = module.sftp_efs.file_system_id
}

output "efs_mount_target_sg_id" {
  value = module.sftp_efs.mount_target_sg_id
}
