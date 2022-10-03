data "aws_caller_identity" "current" {}

data "aws_acm_certificate" "this" {
  domain      = "${var.geomatch_subdomain}.geomatch.org"
  types       = ["AMAZON_ISSUED"]
  statuses    = ["ISSUED"]
  most_recent = true
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
