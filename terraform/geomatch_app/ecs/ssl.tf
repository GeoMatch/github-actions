# resource "aws_acm_certificate" "prod" {
#   domain_name               = var.canonical_domain_name
#   subject_alternative_names = var.alternative_domain_names
#   validation_method         = "DNS"

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_route53_zone" "prod" {
#   name         = var.canonical_domain_name 
#   comment      = "HostedZone created by Route53 Registrar"

#   tags = {
#     Project     = var.project
#   }
# }

# # locals {
# #   route53_records = flatten([
# #     for network_key, network in var.networks : [
# #       for subnet_key, subnet in network.subnets : {
# #         domain_name
# #         name   = dvo.resource_record_name
# #         record = dvo.resource_record_value
# #         type   = dvo.resource_record_type
# #       }
# #     ]
# #   ])
# # }

# resource "aws_route53_record" "prod" {
#   for_each = {
#     for dvo in aws_acm_certificate.prod.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = data.aws_route53_zone.prod.zone_id
# }

# resource "aws_acm_certificate_validation" "prod" {
#   certificate_arn         = aws_acm_certificate.prod.arn
#   validation_record_fqdns = [for record in aws_route53_record.prod : record.fqdn]
# }
