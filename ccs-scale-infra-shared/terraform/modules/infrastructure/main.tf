provider "aws" {
  profile = "default"
  region  = "eu-west-2"

  assume_role {
    role_arn = "arn:aws:iam::${var.aws_account_id}:role/CCS_SCALE_Build"
  }
}

data "aws_ssm_parameter" "nat_eip_ids" {
  name = "${lower(var.environment)}-eip-ids-nat-gateway"
}

data "aws_ssm_parameter" "public_nlb_eip_ids" {
  name = "${lower(var.environment)}-eip-ids-public-nlb"
}

# CDN+ALB custom domain names for CloudFront modules

# FaT CDN
data "aws_ssm_parameter" "hosted_zone_name_cdn" {
  name = "${lower(var.environment)}-hosted-zone-name-cdn"
}

data "aws_ssm_parameter" "hosted_zone_name_cdn_bat_client" {
  name = "/bat/${lower(var.environment)}-hosted-zone-name-cdn-bat-client"
}

data "aws_ssm_parameter" "hosted_zone_name_cdn_bat_backend" {
  name = "/bat/${lower(var.environment)}-hosted-zone-name-cdn-bat-backend"
}

# FaT ALB
data "aws_ssm_parameter" "hosted_zone_name_alb" {
  name = "${lower(var.environment)}-hosted-zone-name-alb"
}

data "aws_ssm_parameter" "hosted_zone_name_alb_bat_client" {
  name = "/bat/${lower(var.environment)}-hosted-zone-name-alb-bat-client"
}

data "aws_ssm_parameter" "hosted_zone_name_alb_bat_backend" {
  name = "/bat/${lower(var.environment)}-hosted-zone-name-alb-bat-backend"
}

module "network" {
  source                 = "./network"
  environment            = var.environment
  vpc_id                 = var.vpc_id
  private_app_subnet_ids = var.private_app_subnet_ids
  public_web_subnet_ids  = var.public_web_subnet_ids
  private_db_subnet_ids  = var.private_db_subnet_ids
  nat_eip_ids            = split(",", data.aws_ssm_parameter.nat_eip_ids.value)
  public_nlb_eip_ids     = split(",", data.aws_ssm_parameter.public_nlb_eip_ids.value)
}

# FaT
module "cloudfront" {
  source                              = "./cloudfront"
  aws_account_id                      = var.aws_account_id
  environment                         = var.environment
  cloudfront_s3_log_retention_in_days = var.cloudfront_s3_log_retention_in_days
  hosted_zone_name_alb                = data.aws_ssm_parameter.hosted_zone_name_alb.value
  hosted_zone_name_cdn                = data.aws_ssm_parameter.hosted_zone_name_cdn.value
}

# BaT Buyer UI
module "cloudfront_bat_client" {
  source                              = "./cloudfront"
  aws_account_id                      = var.aws_account_id
  environment                         = var.environment
  cloudfront_s3_log_retention_in_days = var.cloudfront_s3_log_retention_in_days
  hosted_zone_name_alb                = data.aws_ssm_parameter.hosted_zone_name_alb_bat_client.value
  hosted_zone_name_cdn                = data.aws_ssm_parameter.hosted_zone_name_cdn_bat_client.value
}

# BaT Spree Backend
module "cloudfront_bat_backend" {
  source                              = "./cloudfront"
  aws_account_id                      = var.aws_account_id
  environment                         = var.environment
  cloudfront_s3_log_retention_in_days = var.cloudfront_s3_log_retention_in_days
  hosted_zone_name_alb                = data.aws_ssm_parameter.hosted_zone_name_alb_bat_backend.value
  hosted_zone_name_cdn                = data.aws_ssm_parameter.hosted_zone_name_cdn_bat_backend.value
}
