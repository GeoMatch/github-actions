variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "user_id" {
  # Note: This is not the username, but an easy to read identifier for the user
  # Used for resource naming / tagging
  type = string
}

variable "username" {
  type = string
  # If not supplied, you must set via SSM and re-apply
  default = ""
}

variable "public_key" {
  type = string
  # If not supplied, you must set via SSM and re-apply
  default = ""
}

variable "aws_region" {
  type = string
}

variable "sftp_module" {
  type = object({
    transfer_server_id = string
    sftp_server_up     = bool
    lambda_iam_role_id = string
  })
}

variable "networking_module" {
  type = object({
    vpc_id                     = string
    private_tier_tag           = string
    public_tier_tag            = string
    one_zone_az_name           = string
    one_zone_public_subnet_id  = string
    one_zone_private_subnet_id = string
  })
}
