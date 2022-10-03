terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.10"
    }
  }

  backend "s3" {
    encrypt = true
    bucket  = "geomatch-global-terraform-state"
    key     = "state/global.tfstate"
    region  = "us-east-1"
    profile = "terraform-global"
  }

  required_version = ">= 1.1.8"
}

# TODO: I couldn't find out how not to setup a default provider.
provider "aws" {
  region  = "us-east-1"
  profile = "terraform-global"
}

module "us_east_1" {
  source = "./regional"
}

provider "aws" {
  alias   = "eu_central_1"
  region  = "eu-central-1"
  profile = "terraform-global-eu-central-1"
}

module "eu_central_1" {
  source = "./regional"
  providers = {
    aws = aws.eu_central_1
  }
}
