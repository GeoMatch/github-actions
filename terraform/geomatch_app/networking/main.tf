terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
  }

  required_version = ">= 1.1.8"
}

locals {
  private_tier_tag = "Private"
  public_tier_tag  = "Public"
  # TODO: This should definitely be more deterministic
  one_zone_az_name = data.aws_availability_zones.this.names[0]
}

// We could filter for state==available here,
// but I believe that would make this less deterministic
data "aws_availability_zones" "this" {
  // Filter out Local Zones 
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# tfer--vpc-00bbe46b
resource "aws_vpc" "this" {
  assign_generated_ipv6_cidr_block = false
  # TODO change to 10.0.0.0/16 as recommended https://docs.aws.amazon.com/vpc/latest/userguide/working-with-vpcs.html
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Project     = var.project
    Environment = var.environment
  }

}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.this.id
  count             = length(var.private_subnets)
  cidr_block        = element(var.private_subnets, count.index)
  availability_zone = element(data.aws_availability_zones.this.names, count.index)

  tags = {
    Project     = var.project
    Environment = var.environment
    Tier        = local.private_tier_tag
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = element(var.public_subnets, count.index)
  availability_zone       = element(data.aws_availability_zones.this.names, count.index)
  count                   = length(var.public_subnets)
  map_public_ip_on_launch = true
  # assign_ipv6_address_on_creation                = "false"
  # enable_dns64                                   = "false"
  # enable_resource_name_dns_a_record_on_launch    = "false"
  # enable_resource_name_dns_aaaa_record_on_launch = "false"
  # ipv6_native                                    = "false"
  # private_dns_hostname_type_on_launch            = "ip-name"

  tags = {
    Project     = var.project
    Environment = var.environment
    Tier        = local.public_tier_tag
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Project     = var.project
    Environment = var.environment
    Tier        = local.public_tier_tag
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}
