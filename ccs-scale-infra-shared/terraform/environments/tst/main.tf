#########################################################
# Environment: TST (User Acceptance Testing)
#
# Deploy SCALE resources
#########################################################
terraform {
  backend "s3" {
    bucket         = "scale-terraform-state"
    key            = "ccs-scale-infra-shared-tst"
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
  cidr_block_web = "192.170.1.0/24"
  cidr_block_app = "192.170.3.0/24"
  cidr_block_db  = "192.170.5.0/24"

  # Elastic IPs, provisioned by ccs-scale-bootstrap
  eip_id_nat = "eipalloc-058c4a8af0cc0883d"
  eip_id_nlb = "eipalloc-00ea3efb96a3e0231"
}

data "aws_ssm_parameter" "aws_account_id" {
  name = "account-id-${lower(local.environment)}"
}

module "deploy" {
  source                 = "../../modules/configs/deploy-all"
  aws_account_id         = data.aws_ssm_parameter.aws_account_id.value
  environment            = local.environment
  ecr_access_cidr_blocks = [local.cidr_block_web, local.cidr_block_app, local.cidr_block_db]
  eip_id_nat             = local.eip_id_nat
  eip_id_nlb             = local.eip_id_nlb
}
