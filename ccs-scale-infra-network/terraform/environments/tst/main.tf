#########################################################
# Environment: TST (User Acceptance Testing)
#
# Deploy SCALE resources
#########################################################
terraform {
  backend "s3" {
    bucket         = "scale-terraform-state"
    key            = "ccs-scale-infra-network-tst"
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
  environment    = "TST"
  cidr_block_vpc = "192.170.0.0/16"

  # One AZ
  subnet_configs = {
    "public_web" = {
      "eu-west-2a" = {
        "az_id"      = "2a"
        "cidr_block" = "192.170.1.0/24"
      }
      # Additional AZ blocks (maps) go here. No comma separation required.
    }
    "private_app" = {
      "eu-west-2a" = {
        "az_id"      = "2a"
        "cidr_block" = "192.170.3.0/24"
      }
    }
    "private_db" = {
      "eu-west-2a" = {
        "az_id"      = "2a"
        "cidr_block" = "192.170.5.0/24"
      }
    }
  }

  # Elastic IPs, provisioned by ccs-scale-bootstrap
  eip_id_nat = "eipalloc-058c4a8af0cc0883d"
  eip_id_nlb = "eipalloc-00ea3efb96a3e0231"
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
}
