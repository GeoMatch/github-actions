
output "vpc_id" {
  value = aws_vpc.this.id
}

output "private_tier_tag" {
  value = local.private_tier_tag
}

output "public_tier_tag" {
  value = local.public_tier_tag
}
