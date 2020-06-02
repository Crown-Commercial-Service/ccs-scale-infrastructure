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

  # Elastic IPs, provisioned by ccs-scale-bootstrap
  eip_id_nat = "eipalloc-058c4a8af0cc0883d"
  eip_id_nlb = "eipalloc-00ea3efb96a3e0231"
}

data "aws_ssm_parameter" "aws_account_id" {
  name = "account-id-${lower(local.environment)}"
}

module "deploy" {
  source         = "../../modules/configs/deploy-all"
  aws_account_id = data.aws_ssm_parameter.aws_account_id.value
  environment    = local.environment
  eip_id_nat     = local.eip_id_nat
  eip_id_nlb     = local.eip_id_nlb
}
