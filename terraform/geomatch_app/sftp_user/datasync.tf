resource "aws_datasync_task" "s3_to_efs" {
  name                     = "${local.name_prefix}-datasync-sftp-to-efs"
  source_location_arn      = aws_datasync_location_s3.source.arn
  destination_location_arn = aws_datasync_location_efs.destination.arn
  #   cloudwatch_log_group_arn = aws_cloudwatch_log_group.datasync_logs.arn
  schedule {
    # 8/9 EST depending on DST
    schedule_expression = "cron(0 13 ? * * *)"
  }

  # https://docs.aws.amazon.com/datasync/latest/userguide/API_Options.html
  options {
    # Permissions are set via the access point defined
    # in datasync_efs.tf
    uid               = "NONE" 
    gid               = "NONE" 
    posix_permissions = "NONE"
  }

  # TODO: S3 reports (supported by AWS, see documentation for this resource)

  tags = {
    Project     = var.project
    Environment = var.environment
    UserId      = var.user_id
  }
}
