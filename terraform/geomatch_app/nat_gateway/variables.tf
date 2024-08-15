variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "public_subnet_cidr_block" {
  type        = string
  description = "The CIDR block for the nat gateway."
}

variable "networking_module" {
  type = object({
    vpc_id                     = string
    one_zone_az_name           = string
    one_zone_public_subnet_id  = string
    one_zone_private_subnet_id = string
    tier_tag_private           = string
    tier_tag_public            = string
    internet_gateway_id        = string
  })
}
