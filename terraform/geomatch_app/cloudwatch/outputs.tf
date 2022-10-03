output "kms_arn" {
  value = aws_kms_key.cloudwatch.arn
}

output "log_group_prefix" {
  value = "/${var.project}-${var.environment}"
}

output "log_group_retention_in_days" {
  value = var.log_group_retention_in_days
}
