#########################################################
# Environment: DEV
#
# Deploy SCALE resources
#########################################################
terraform {
  backend "s3" {
    bucket         = "scale-terraform-state"
    key            = "ccs-scale-infra-shared-dev"
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
  environment     = "DEV"
  cidr_blocks_web = ["192.168.1.0/24"]
  cidr_blocks_app = ["192.168.3.0/24"]
  cidr_blocks_db  = ["192.168.5.0/24"]

  # Elastic IPs, provisioned by ccs-scale-bootstrap
  eip_id_nat = "eipalloc-0eccfa091115cf688"
  eip_id_nlb = "eipalloc-05a9678206ee28099"
}

data "aws_ssm_parameter" "aws_account_id" {
  name = "account-id-${lower(local.environment)}"
}

module "deploy" {
  source                 = "../../modules/configs/deploy-all"
  aws_account_id         = data.aws_ssm_parameter.aws_account_id.value
  environment            = local.environment
  ecr_access_cidr_blocks = flatten([local.cidr_blocks_web, local.cidr_blocks_app, local.cidr_blocks_db])
  eip_id_nat             = local.eip_id_nat
  eip_id_nlb             = local.eip_id_nlb
  db_cidr_blocks         = local.cidr_blocks_db
}
