resource "aws_datasync_task" "this" {
  name                     = "${local.name_prefix}-datasync-efs-to-s3"
  source_location_arn      = aws_datasync_location_efs.source.arn
  destination_location_arn = aws_datasync_location_s3.destination.arn
  #   cloudwatch_log_group_arn = aws_cloudwatch_log_group.datasync_logs.arn
  schedule {
    # Every 10min
    schedule_expression = "cron(0/10 * * * ? *)"
  }

  # TODO: S3 reports (supported by AWS, see documentation for this resource)

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}
