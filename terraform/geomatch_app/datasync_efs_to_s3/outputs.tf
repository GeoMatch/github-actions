output "s3_bucket_arn" {
  value = aws_s3_bucket.this.arn
}

output "efs_fs_policy_document_json" {
  value = data.aws_iam_policy_document.root_fs_access.json
}
