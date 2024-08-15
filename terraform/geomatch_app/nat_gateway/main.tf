terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }

    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
  }

  required_version = ">= 1.1.8"
}


resource "aws_subnet" "this" {
  vpc_id                  = var.networking_module.vpc_id
  cidr_block              = var.public_subnet_cidr_block
  availability_zone       = var.networking_module.one_zone_az_name
  map_public_ip_on_launch = true

  tags = {
    Project     = var.project
    Environment = var.environment
    Tier        = var.networking_module.tier_tag_public
    Name        = "Public subnet for NAT Gateway"
  }
}

resource "aws_eip" "this" {
  domain = "vpc"
  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.this.id
  subnet_id     = aws_subnet.this.id

  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "${var.project}-${var.environment}-nat-gateway"
  }
}

resource "aws_route_table" "this" {
  vpc_id = var.networking_module.vpc_id

  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "${var.project}-${var.environment}-nat-gateway-route-table"
  }
}

resource "aws_route_table_association" "this" {
  route_table_id = aws_route_table.this.id
  subnet_id      = aws_subnet.this.id
}

# VPC local should be configured by default
resource "aws_route" "internet" {
  route_table_id         = aws_route_table.this.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.networking_module.internet_gateway_id
}
