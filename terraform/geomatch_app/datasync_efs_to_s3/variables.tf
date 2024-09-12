variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "name_suffix" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "efs_module" {
  sensitive = true
  type = object({
    file_system_id     = string
    file_system_arn    = string
    mount_target_sg_id = string
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
