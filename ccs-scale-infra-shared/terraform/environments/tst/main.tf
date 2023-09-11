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
  environment = "TST"
  transit_gateway_routes = {
    "dmp_cicd" = {
      destination_cidr_block = "172.31.0.0/16"
      transit_gateway_id     = "tgw-0fddd8aeb224fe171"
    }
  }

}

data "aws_ssm_parameter" "aws_account_id" {
  name = "account-id-${lower(local.environment)}"
}

module "deploy" {
  source                 = "../../modules/configs/deploy-all"
  aws_account_id         = data.aws_ssm_parameter.aws_account_id.value
  environment            = local.environment
  transit_gateway_routes = local.transit_gateway_routes
}
