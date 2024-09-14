terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.1"
    }
  }

  required_version = ">= 1.1.8"
}

# provider "aws" {
#   region  = "us-east-1"
#   profile = "terraform-global"
# }

# module "us_east_1" {
#   source = "./regional"
# }

# provider "aws" {
#   alias   = "eu_central_1"
#   region  = "eu-central-1"
#   profile = "terraform-global-eu-central-1"
# }

# module "eu_central_1" {
#   source = "./regional"
#   providers = {
#     aws = aws.eu_central_1
#   }
# }
