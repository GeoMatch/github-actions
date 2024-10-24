variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "ecr_name_suffix" {
  type    = string
  default = "app"
}

variable "ssm_name_prefix" {
  type        = string
  description = "should be '/{project}/{environment}'"
}
