#########################################################
# Config: deploy-all
#
# This configuration will deploy all components.
#########################################################
provider "aws" {
  profile = "default"
  region  = "eu-west-2"
  version = "~> 2.70.0"

  assume_role {
    role_arn = "arn:aws:iam::${var.aws_account_id}:role/CCS_SCALE_Build"
  }
}

module "globals" {
  source = "../../globals"
}

data "aws_ssm_parameter" "vpc_id" {
  name = "${lower(var.environment)}-vpc-id"
}

data "aws_ssm_parameter" "public_web_subnet_ids" {
  name = "${lower(var.environment)}-public-web-subnet-ids"
}

data "aws_ssm_parameter" "private_app_subnet_ids" {
  name = "${lower(var.environment)}-private-app-subnet-ids"
}

data "aws_ssm_parameter" "private_db_subnet_ids" {
  name = "${lower(var.environment)}-private-db-subnet-ids"
}

data "aws_ssm_parameter" "cidr_blocks_web" {
  name = "${lower(var.environment)}-cidr-blocks-web"
}

data "aws_ssm_parameter" "cidr_blocks_app" {
  name = "${lower(var.environment)}-cidr-blocks-app"
}

data "aws_ssm_parameter" "cidr_blocks_db" {
  name = "${lower(var.environment)}-cidr-blocks-db"
}

data "aws_ssm_parameter" "bastion_kms_key_id" {
  name = "${lower(var.environment)}-bastion-encryption-key"
}

data "aws_ssm_parameter" "cidr_blocks_allowed_external_ccs" {
  name = "${lower(var.environment)}-cidr-blocks-allowed-external-ccs"
}

data "aws_ssm_parameter" "cidr_blocks_allowed_external_spark" {
  name = "${lower(var.environment)}-cidr-blocks-allowed-external-spark"
}

data "aws_ssm_parameter" "cidr_blocks_allowed_external_cognizant" {
  name = "${lower(var.environment)}-cidr-blocks-allowed-external-cognizant"
}

locals {
  # Normalised CIDR blocks (accounting for 'none' i.e. "-" as value in SSM parameter)
  cidr_blocks_allowed_external_ccs       = data.aws_ssm_parameter.cidr_blocks_allowed_external_ccs.value != "-" ? split(",", data.aws_ssm_parameter.cidr_blocks_allowed_external_ccs.value) : []
  cidr_blocks_allowed_external_spark     = data.aws_ssm_parameter.cidr_blocks_allowed_external_spark.value != "-" ? split(",", data.aws_ssm_parameter.cidr_blocks_allowed_external_spark.value) : []
  cidr_blocks_allowed_external_cognizant = data.aws_ssm_parameter.cidr_blocks_allowed_external_cognizant.value != "-" ? split(",", data.aws_ssm_parameter.cidr_blocks_allowed_external_cognizant.value) : []
}

module "kms" {
  source = "../../kms"
  aws_account_id                      = var.aws_account_id
  environment                         = var.environment
}

module "infrastructure" {
  source                              = "../../infrastructure"
  aws_account_id                      = var.aws_account_id
  environment                         = var.environment
  vpc_id                              = data.aws_ssm_parameter.vpc_id.value
  private_app_subnet_ids              = split(",", data.aws_ssm_parameter.private_app_subnet_ids.value)
  public_web_subnet_ids               = split(",", data.aws_ssm_parameter.public_web_subnet_ids.value)
  private_db_subnet_ids               = split(",", data.aws_ssm_parameter.private_db_subnet_ids.value)
  cloudfront_s3_log_retention_in_days = var.cloudfront_s3_log_retention_in_days
  logitio_port                        = var.logitio_port
}

module "ssm" {
  source                 = "../../ssm"
  environment            = var.environment
  lb_private_arn         = module.infrastructure.lb_private_arn
  lb_private_db_arn      = module.infrastructure.lb_private_db_arn
  lb_public_alb_arn      = module.infrastructure.lb_public_alb_arn
  vpc_link_id            = module.infrastructure.vpc_link_id
  lb_private_dns         = module.infrastructure.lb_private_dns
  lb_private_db_dns      = module.infrastructure.lb_private_db_dns
  cloudwatch_kms_key_arn = module.kms.cloudwatch_kms_key_arn
}

module "bastion" {
  source                       = "../../bastion"
  environment                  = var.environment
  vpc_id                       = data.aws_ssm_parameter.vpc_id.value
  subnet_id                    = split(",", data.aws_ssm_parameter.public_web_subnet_ids.value)[0]
  db_cidr_blocks               = split(",", data.aws_ssm_parameter.cidr_blocks_db.value)
  bastion_kms_key_id           = data.aws_ssm_parameter.bastion_kms_key_id.value
  cidr_blocks_allowed_external = concat(local.cidr_blocks_allowed_external_ccs, local.cidr_blocks_allowed_external_spark, local.cidr_blocks_allowed_external_cognizant)
  kali_instance                = var.kali_instance
  kali_instance_type           = var.kali_instance_type
}

# CloudTrail is not really required in lower enviromnments.
# We should be able to turn this off easily using the module 'count=0' property when
# it becomes available in Terraform 0.13 if required
# https://www.hashicorp.com/blog/announcing-the-terraform-0-13-beta/
module "cloudtrail" {
  source                              = "../../cloudtrail"
  aws_account_id                      = var.aws_account_id
  environment                         = var.environment
  cloudtrail_cw_log_retention_in_days = var.cloudtrail_cw_log_retention_in_days
  cloudtrail_s3_log_retention_in_days = var.cloudtrail_s3_log_retention_in_days
  cloudwatch_s3_force_destroy         = var.cloudwatch_s3_force_destroy
  cloudtrail_kms_key_arn              = module.kms.cloudtrail_kms_key_arn
}
