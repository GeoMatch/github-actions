data "github_ip_ranges" "this" {}

resource "aws_subnet" "ecs" {
  vpc_id            = var.networking_module.vpc_id
  cidr_block        = var.private_subnet_cidr_block
  availability_zone = var.networking_module.one_zone_az_name

  tags = {
    Project     = var.project
    Environment = var.environment
    Tier        = var.networking_module.tier_tag_private
    Name        = "${var.project}-${var.environment}-${var.name}-subnet"
  }
}

resource "aws_security_group" "ecs" {
  name   = "${var.project}-${var.environment}-${var.name}-ecs-sg"
  vpc_id = var.networking_module.vpc_id

  tags = {
    Project     = var.project
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "alb_egress_to_ecs" {
  security_group_id            = var.alb_module.alb_sg_id
  ip_protocol                  = -1
  referenced_security_group_id = aws_security_group.ecs.id

  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "${var.project}-${var.environment}-${var.name}-alb-egress-ecs"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ecs_ingress_from_alb" {
  security_group_id            = aws_security_group.ecs.id
  ip_protocol                  = -1
  referenced_security_group_id = var.alb_module.alb_sg_id

  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "${var.project}-${var.environment}-${var.name}-ecs-ingress-alb"
  }
}

# TODO(P2): Need to actually limit this to the VPC (either by VPC endpoint, or filtering by SSM/ECR FQDN)
resource "aws_vpc_security_group_egress_rule" "ecs_egress_vpc" {
  security_group_id = aws_security_group.ecs.id
  description       = "Allow all outbound connections to VPC"
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
  # cidr_ipv4         = var.networking_module.cidr_block
  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "${var.project}-${var.environment}-${var.name}-ecs-egress-vpc"
  }
}

# Could replace with VPC endpoint
resource "aws_vpc_security_group_ingress_rule" "ecs_ingress_vpc" {
  security_group_id = aws_security_group.ecs.id
  description       = "Allow incoming connections on port 443 from VPC"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = var.networking_module.cidr_block
  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "${var.project}-${var.environment}-${var.name}-ecs-ingress-vpc"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ecs_ingress_nfs" {
  security_group_id = aws_security_group.ecs.id
  description       = "NFS traffic over TCP on port 2049"
  from_port         = 2049
  to_port           = 2049
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "${var.project}-${var.environment}-${var.name}-ecs-ingress-nfs"
  }
}

resource "aws_vpc_security_group_egress_rule" "ecs_egress_github_git_ipv4" {
  count             = length(data.github_ip_ranges.this.git_ipv4)
  security_group_id = aws_security_group.ecs.id
  description       = "Github git IPV4 traffick"
  cidr_ipv4         = element(data.github_ip_ranges.this.git_ipv4, count.index)
  ip_protocol       = "-1"
  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "${var.project}-${var.environment}-${var.name}-ecs-egress-gh-ipv4"
  }
}
# resource "aws_vpc_security_group_egress_rule" "ecs_egress_github_git_ipv6" {
#   count             = length(data.github_ip_ranges.this.git_ipv6)
#   security_group_id = aws_security_group.ecs.id
#   description       = "Github git IPV6 traffick"
#   cidr_ipv6         = element(data.github_ip_ranges.this.git_ipv6, count.index)
#   ip_protocol       = "-1"
#   tags = {
#     Project     = var.project
#     Environment = var.environment
#     Name        = "${var.project}-${var.environment}-${var.name}-ecs-egress-gh-ipv6"
#   }
# }

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.networking_module.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "${var.project}-${var.environment}-${var.name}-endpoint-s3"
  }
}

resource "aws_route_table" "this" {
  vpc_id = var.networking_module.vpc_id

  tags = {
    Project     = var.project
    Environment = var.environment
    Name        = "${var.project}-${var.environment}-${var.name}-route-table"
  }
}

# Could alternatively use vpc_endpoints (see commented out code below)
resource "aws_route" "vpc" {
  # If this fails, you probably need to import the route.
  # Add this to your root module, and try again:
  # import {
  #   to = module.sagemaker.aws_route.vpc
  #   id = "${module.sagemaker.route_table_id}_${module.networking.cidr_block}"
  # }
  # See: https://github.com/hashicorp/terraform-provider-aws/issues/33117
  route_table_id = aws_route_table.this.id
  nat_gateway_id = var.nat_gateway_module.nat_gateway_id
  # TODO: This defeats the purpose of other routes. Limit to AWS IPs
  destination_cidr_block = "0.0.0.0/0"
}

# TODO: might need web as well for extension integration?
resource "aws_route" "github_git_ipv4" {
  count                  = length(data.github_ip_ranges.this.git_ipv4)
  route_table_id         = aws_route_table.this.id
  destination_cidr_block = element(data.github_ip_ranges.this.git_ipv4, count.index)
  nat_gateway_id         = var.nat_gateway_module.nat_gateway_id
}

# resource "aws_route" "github_git_ipv6" {
#   count                       = length(data.github_ip_ranges.this.git_ipv6)
#   route_table_id              = aws_route_table.this.id
#   destination_ipv6_cidr_block = element(data.github_ip_ranges.this.git_ipv6, count.index)
#   nat_gateway_id              = var.nat_gateway_module.nat_gateway_id
# }

# This automatically configures the route on the route table to send traffic to the VPC endpoint
resource "aws_vpc_endpoint_route_table_association" "s3" {
  route_table_id  = aws_route_table.this.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_route_table_association" "private_subnet" {
  route_table_id = aws_route_table.this.id
  subnet_id      = aws_subnet.ecs.id
}

# resource "aws_vpc_endpoint" "interface_endpoints" {
# Are these prefix lists? https://docs.aws.amazon.com/vpc/latest/userguide/working-with-aws-managed-prefix-lists.html
# They aren't listed
#   for_each = toset([
#     "com.amazonaws.${data.aws_region.current.name}.sagemaker.api",
#     "com.amazonaws.${var.aws_region}.sagemaker.runtime",
#   ])

#   vpc_id              = var.networking_module.vpc_id
#   service_name        = each.key
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = [var.networking_module.one_zone_private_subnet_id]
#   private_dns_enabled = true

#   security_group_ids = [
#     aws_security_group.vpc_endpoint.id
#   ]

#   tags = {
#     Project     = var.project
#     Environment = var.environment
#     Name        = "${var.project}-${var.environment}-sagemaker-endpoint-${each.key}"
#   }
# }
