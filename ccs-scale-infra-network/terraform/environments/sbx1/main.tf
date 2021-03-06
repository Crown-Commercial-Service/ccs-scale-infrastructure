#########################################################
# Environment: SBX1
#
# Deploy SCALE resources
#########################################################
terraform {
  backend "s3" {
    bucket         = "scale-terraform-state"
    key            = "ccs-scale-infra-network-sbx1"
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
  environment    = "SBX1"
  cidr_block_vpc = "192.168.0.0/16"

  # One AZ
  subnet_configs = {
    "public_web" = {
      "eu-west-2a" = {
        "az_id"      = "2a"
        "cidr_block" = "192.168.1.0/24"
      }
      "eu-west-2b" = {
        "az_id"      = "2b"
        "cidr_block" = "192.168.4.0/24"
      }
      # Additional AZ blocks (maps) go here. No comma separation required.
    }
    "private_app" = {
      "eu-west-2a" = {
        "az_id"      = "2a"
        "cidr_block" = "192.168.3.0/24"
      }
    }
    "private_db" = {
      "eu-west-2a" = {
        "az_id"      = "2a"
        "cidr_block" = "192.168.5.0/24"
      }
      "eu-west-2b" = {
        "az_id"      = "2b"
        "cidr_block" = "192.168.11.0/24"
      }
    }
  }
}

data "aws_ssm_parameter" "aws_account_id" {
  name = "account-id-${lower(local.environment)}"
}

module "vpc" {
  source         = "../../modules/vpc"
  aws_account_id = data.aws_ssm_parameter.aws_account_id.value
  environment    = local.environment
  cidr_block_vpc = local.cidr_block_vpc
  subnet_configs = local.subnet_configs
}

module "ssm" {
  source                 = "../../modules/ssm"
  aws_account_id         = data.aws_ssm_parameter.aws_account_id.value
  environment            = local.environment
  vpc_id                 = module.vpc.vpc_id
  public_web_subnet_ids  = module.vpc.public_web_subnet_ids
  private_app_subnet_ids = module.vpc.private_app_subnet_ids
  private_db_subnet_ids  = module.vpc.private_db_subnet_ids
  cidr_block_vpc         = local.cidr_block_vpc
  cidr_blocks_web        = [local.subnet_configs["public_web"]["eu-west-2a"]["cidr_block"]]
  cidr_blocks_app        = [local.subnet_configs["private_app"]["eu-west-2a"]["cidr_block"]]
  cidr_blocks_db         = [local.subnet_configs["private_db"]["eu-west-2a"]["cidr_block"], local.subnet_configs["private_db"]["eu-west-2b"]["cidr_block"]]
}
