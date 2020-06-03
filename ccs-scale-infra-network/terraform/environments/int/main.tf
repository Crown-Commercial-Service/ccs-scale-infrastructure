#########################################################
# Environment: INT (Integration Testing)
#
# Deploy SCALE resources
#########################################################
terraform {
  backend "s3" {
    bucket         = "scale-terraform-state"
    key            = "ccs-scale-infra-network-int"
    region         = "eu-west-2"
    dynamodb_table = "scale_terraform_state_lock"
    encrypt        = true
  }
}

provider "aws" {
  profile = "default"
  region  = "eu-west-2"
}

locals {
  environment    = "INT"
  cidr_block_vpc = "192.169.0.0/16"

  # One AZ
  subnet_configs = {
    "public_web" = {
      "eu-west-2a" = {
        "az_id"      = "2a"
        "cidr_block" = "192.169.1.0/24"
      }
      # Additional AZ blocks (maps) go here. No comma separation required.
    }
    "private_app" = {
      "eu-west-2a" = {
        "az_id"      = "2a"
        "cidr_block" = "192.169.3.0/24"
      }
    }
    "private_db" = {
      "eu-west-2a" = {
        "az_id"      = "2a"
        "cidr_block" = "192.169.5.0/24"
      }
    }
  }
}

data "aws_ssm_parameter" "aws_account_id" {
  name = "account-id-${lower(local.environment)}"
}

module "vpc" {
  source         = "../../modules/vpc-one-az"
  aws_account_id = data.aws_ssm_parameter.aws_account_id.value
  environment    = local.environment
  cidr_block_vpc = local.cidr_block_vpc
  cidr_block_web = local.cidr_block_web
  cidr_block_app = local.cidr_block_app
  cidr_block_db  = local.cidr_block_db
}

module "ssm" {
  source                 = "../../modules/ssm"
  aws_account_id         = data.aws_ssm_parameter.aws_account_id.value
  environment            = local.environment
  vpc_id                 = module.vpc.vpc_id
  public_web_subnet_ids  = module.vpc.public_web_subnet_ids
  private_app_subnet_ids = module.vpc.private_app_subnet_ids
  private_db_subnet_ids  = module.vpc.private_db_subnet_ids
  cidr_blocks_web        = local.subnet_configs["public_web"]["eu-west-2a"]["cidr_block"]
  cidr_blocks_app        = local.subnet_configs["private_app"]["eu-west-2a"]["cidr_block"]
  cidr_blocks_db         = local.subnet_configs["private_db"]["eu-west-2a"]["cidr_block"]
}
