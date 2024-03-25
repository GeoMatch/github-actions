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

module "global-us-networking" {
  source          = "../geomatch_app/networking"
  project         = "geomatch-us"
  environment     = "global"
  aws_region      = "us-east-1"
  vpc_cidr_block  = "10.1.0.0/16"
  public_subnets  = ["10.1.0.0/24", "10.1.1.0/24", "10.1.2.0/24"]
  private_subnets = ["10.1.100.0/24", "10.1.101.0/24", "10.1.102.0/24"]
}

module "global-us-sftp" {
  # In the US, SFTP is provided globally to share the SFTP server.
  source            = "../geomatch_app/sftp"
  project           = "geomatch-us"
  environment       = "global"
  aws_region        = "us-east-1"
  networking_module = module.global-us-networking
  sftp_server_up    = false
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
