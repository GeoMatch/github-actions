variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "name" {
  type = string
}

variable "limit_to_su_vpn" {
  type = bool
}

variable "su_vpn_end_user_cidr" {
  # TODO: Move to global config in central account
  # https://uit.stanford.edu/guide/lna/network-numbers
  type = string
}

variable "require_cardinal_cloud_auth" {
  type = bool
}

variable "networking_module" {
  type = object({
    vpc_id                     = string
    private_tier_tag           = string
    public_tier_tag            = string
    one_zone_az_name           = string
    one_zone_public_subnet_id  = string
    one_zone_private_subnet_id = string
    cidr_block                 = string
    tier_tag_private           = string
    tier_tag_public            = string
  })
}
