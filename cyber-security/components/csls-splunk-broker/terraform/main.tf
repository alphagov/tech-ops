terraform {
  backend "s3" {
  }
  required_providers {
    cloudfoundry = ">= 0.11.0"
  }
  required_version = "= 0.12.23"
}

provider "cloudfoundry" {
  version  = "0.11.0"
  api_url  = "https://api.cloud.service.gov.uk"
  user     = var.cf_username
  password = var.cf_password
}

provider "aws" {
  region = "eu-west-2"
  assume_role {
    role_arn = var.target_deployer_role_arn
  }
  version = "~> 2.37"
}

provider "aws" {
  alias  = "csls"
  region = "eu-west-2"
  assume_role {
    role_arn = var.csls_deployer_role_arn
  }
  version = "~> 2.37"
}

data "aws_route53_zone" "main" {
  name = var.target_zone_name
}

resource "random_password" "csls_hmac_secret" {
  length  = 32
  special = false
}

