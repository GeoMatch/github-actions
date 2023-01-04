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

variable "networking_module" {
  type = object({
    vpc_id                     = string
    one_zone_az_name           = string
    one_zone_public_subnet_id  = string
    one_zone_private_subnet_id = string
  })
}
