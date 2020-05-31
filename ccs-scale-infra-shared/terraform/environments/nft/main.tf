#########################################################
# Environment: NFT (Non Functional Testing)
#
# Deploy SCALE resources
#########################################################
terraform {
  backend "s3" {
    bucket         = "scale-terraform-state"
    key            = "ccs-scale-infra-shared-nft"
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
  environment    = "NFT"
  cidr_block_vpc = "192.170.0.0/16"
  cidr_block_web_2a = "192.170.1.0/24"
  cidr_block_web_2b = "192.170.7.0/24"
  cidr_block_web_2c = "192.170.13.0/24"
  cidr_block_app_2a = "192.170.3.0/24"
  cidr_block_app_2b = "192.170.9.0/24"
  cidr_block_app_2c = "192.170.15.0/24"
  cidr_block_db_2a  = "192.170.5.0/24"
  cidr_block_db_2a  = "192.170.11.0/24"
  cidr_block_db_2a  = "192.170.17.0/24"

  # Elastic IPs, provisioned by ccs-scale-bootstrap
  eip_id_nat = ""
  eip_id_nlb = ""
}

data "aws_ssm_parameter" "aws_account_id" {
  name = "account-id-${lower(local.environment)}"
}

module "deploy" {
  source                 = "../../modules/configs/deploy-all"
  aws_account_id         = data.aws_ssm_parameter.aws_account_id.value
  environment            = local.environment
  ecr_access_cidr_blocks = [local.cidr_block_web_2a, local.cidr_block_web_2b, local.cidr_block_web_2c, local.cidr_block_app_2a, local.cidr_block_app_2b, local.cidr_block_app_2c, local.cidr_block_db_2a, local.cidr_block_db_2b, local.cidr_block_db_2c]
  eip_id_nat             = local.eip_id_nat
  eip_id_nlb             = local.eip_id_nlb
}
