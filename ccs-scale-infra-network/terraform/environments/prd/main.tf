#########################################################
# Environment: PRD (Production)
#
# Deploy SCALE resources
#########################################################
terraform {
  backend "s3" {
    bucket         = "scale-terraform-state"
    key            = "ccs-scale-infra-network-prd"
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
  environment    = "PRD"
  cidr_block_vpc = "192.168.0.0/16"

  subnet_configs = {
    "public_web" = {
      "eu-west-2a" = {
        "az_id"      = "2a"
        "cidr_block" = "192.168.51.0/24"
      }
      "eu-west-2b" = {
        "az_id"      = "2b"
        "cidr_block" = "192.168.54.0/24"
      }
      "eu-west-2c" = {
        "az_id"      = "2c"
        "cidr_block" = "192.168.57.0/24"
      }
    }
    "private_app" = {
      "eu-west-2a" = {
        "az_id"      = "2a"
        "cidr_block" = "192.168.52.0/24"
      }
      "eu-west-2b" = {
        "az_id"      = "2b"
        "cidr_block" = "192.168.55.0/24"
      }
      "eu-west-2c" = {
        "az_id"      = "2c"
        "cidr_block" = "192.168.58.0/24"
      }
    }
    "private_db" = {
      "eu-west-2a" = {
        "az_id"      = "2a"
        "cidr_block" = "192.168.53.0/24"
      }
      "eu-west-2b" = {
        "az_id"      = "2b"
        "cidr_block" = "192.168.56.0/24"
      }
      "eu-west-2c" = {
        "az_id"      = "2c"
        "cidr_block" = "192.168.59.0/24"
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
  cidr_blocks_web        = [local.subnet_configs["public_web"]["eu-west-2a"]["cidr_block"], local.subnet_configs["public_web"]["eu-west-2b"]["cidr_block"], local.subnet_configs["public_web"]["eu-west-2c"]["cidr_block"]]
  cidr_blocks_app        = [local.subnet_configs["private_app"]["eu-west-2a"]["cidr_block"],local.subnet_configs["private_app"]["eu-west-2b"]["cidr_block"], local.subnet_configs["private_app"]["eu-west-2c"]["cidr_block"]]
  cidr_blocks_db         = [local.subnet_configs["private_db"]["eu-west-2a"]["cidr_block"], local.subnet_configs["private_db"]["eu-west-2b"]["cidr_block"], local.subnet_configs["private_db"]["eu-west-2c"]["cidr_block"]]
}
