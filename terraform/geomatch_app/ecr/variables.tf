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
