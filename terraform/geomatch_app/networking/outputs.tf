
output "vpc_id" {
  value = aws_vpc.this.id
}

output "private_tier_tag" {
  value = local.private_tier_tag
}

output "public_tier_tag" {
  value = local.public_tier_tag
}

# We currently run ECS / EFS / RDS in a single AZ.
# The following one_zone outputs specify which AZ and private / public subnets
# to use for those resources. 

output "one_zone_az_name" {
  # This should match the index created for each.
  value = data.aws_availability_zones.this.names[0]
}

output "one_zone_public_subnet_id" {
  value = aws_subnet.public[0].id
}

output "one_zone_private_subnet_id" {
  value = aws_subnet.private[0].id
}
