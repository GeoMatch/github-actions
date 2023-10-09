locals {
  us_global_tag = "us-global"
}

resource "aws_vpc" "us_global" {
  assign_generated_ipv6_cidr_block = false
  cidr_block                       = "10.1.0.0/16"
  enable_dns_hostnames             = true
  enable_dns_support               = true
  instance_tenancy                 = "default"

  tags = {
    Project = local.us_global_tag
  }
}

resource "aws_subnet" "sftp_us" {
  vpc_id                  = aws_vpc.us_global.id
  map_public_ip_on_launch = true
  cidr_block              = "10.1.0.0/24"

  tags = {
    Project = local.us_global_tag
    Tier    = "Public"
  }
}


resource "aws_internet_gateway" "us_global" {
  vpc_id = aws_vpc.us_global.id

  tags = {
    Project = local.us_global_tag
  }
}

resource "aws_route_table" "us_global" {
  vpc_id = aws_vpc.us_global.id

  tags = {
    Project = local.us_global_tag
  }
}

resource "aws_route" "us_global" {
  route_table_id         = aws_route_table.us_global.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.us_global.id
}

resource "aws_route_table_association" "us_global" {
  subnet_id      = aws_subnet.sftp_us.id
  route_table_id = aws_route_table.us_global.id
}
