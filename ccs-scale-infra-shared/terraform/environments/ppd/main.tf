#########################################################
# Environment: PPD (Pre Production)
#
# Deploy SCALE resources
#########################################################
terraform {
  backend "s3" {
    bucket         = "scale-terraform-state"
    key            = "ccs-scale-infra-shared-ppd"
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
  environment = "PPD"
}

data "aws_ssm_parameter" "aws_account_id" {
  name = "account-id-${lower(local.environment)}"
}

data "aws_ssm_parameter" "tgw_network_cidr" {
  name = "tgw-network-cidr-${lower(local.environment)}"
}

module "deploy" {
  source                              = "../../modules/configs/deploy-all"
  aws_account_id                      = data.aws_ssm_parameter.aws_account_id.value
  environment                         = local.environment
  cloudtrail_cw_log_retention_in_days = 90
  cloudtrail_s3_log_retention_in_days = 2555 #7 years
  cloudwatch_s3_force_destroy         = false
  cloudfront_s3_log_retention_in_days = 2555 #7 years
  transit_gateway_networks = {
    "dmp_cicd" = {
      cidr_block  = data.aws_ssm_parameter.tgw_network_cidr.value
      rule_number = 300
    }
  }
}
