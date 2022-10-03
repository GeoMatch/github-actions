variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}


variable "ssm_name_prefix" {
  type        = string
  description = "should be '/{project}/{environment}'"
}

variable "cloudwatch_module" {
  type = object({
    log_group_prefix            = string
    log_group_retention_in_days = number
    kms_arn                     = string
  })
}

variable "codebuild_environment_variables" {
  description = "List of extra environment variables to pass to codebuild"
  type = list(object({
    name  = string
    value = any
  }))
  default = []
}
