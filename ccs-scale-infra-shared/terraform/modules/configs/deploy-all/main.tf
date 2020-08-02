#########################################################
# Config: deploy-all
#
# This configuration will deploy all components.
#########################################################
provider "aws" {
  profile = "default"
  region  = "eu-west-2"

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

module "infrastructure" {
  source                 = "../../infrastructure"
  aws_account_id         = var.aws_account_id
  environment            = var.environment
  vpc_id                 = data.aws_ssm_parameter.vpc_id.value
  private_app_subnet_ids = split(",", data.aws_ssm_parameter.private_app_subnet_ids.value)
  public_web_subnet_ids  = split(",", data.aws_ssm_parameter.public_web_subnet_ids.value)
  private_db_subnet_ids  = split(",", data.aws_ssm_parameter.private_db_subnet_ids.value)
}

module "ssm" {
  source                    = "../../ssm"
  environment               = var.environment
  lb_private_arn            = module.infrastructure.lb_private_arn
  lb_private_db_arn         = module.infrastructure.lb_private_db_arn
  lb_public_arn             = module.infrastructure.lb_public_arn
  lb_public_alb_arn         = module.infrastructure.lb_public_alb_arn
  vpc_link_id               = module.infrastructure.vpc_link_id
  lb_private_dns            = module.infrastructure.lb_private_dns
  lb_private_db_dns         = module.infrastructure.lb_private_db_dns
  cloudfront_id             = module.infrastructure.cloudfront_id
  lb_public_alb_listner_arn = module.infrastructure.lb_public_alb_listner_arn
}

module "bastion" {
  source         = "../../bastion"
  environment    = var.environment
  vpc_id         = data.aws_ssm_parameter.vpc_id.value
  subnet_id      = split(",", data.aws_ssm_parameter.public_web_subnet_ids.value)[0]
  db_cidr_blocks = split(",", data.aws_ssm_parameter.cidr_blocks_db.value)
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
}
