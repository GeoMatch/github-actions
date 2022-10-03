variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "log_group_retention_in_days" {
  type    = number
  default = 365
}
