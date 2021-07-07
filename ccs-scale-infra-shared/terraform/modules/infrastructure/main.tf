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
  logitio_port           = var.logitio_port
}

# FaT
module "cloudfront" {
  source                              = "./cloudfront"
  aws_account_id                      = var.aws_account_id
  environment                         = var.environment
  cloudfront_s3_log_retention_in_days = var.cloudfront_s3_log_retention_in_days
  hosted_zone_name_alb                = data.aws_ssm_parameter.hosted_zone_name_alb.value
  hosted_zone_name_cdn                = data.aws_ssm_parameter.hosted_zone_name_cdn.value
  resource_label                      = "fat-buyer-ui"
  cache_default_ttl                   = 3600
  cache_max_ttl                       = 86400
  content_security_policy             = "default-src 'none'; img-src 'self' *.crowncommercial.gov.uk *.s3.eu-west-2.amazonaws.com www.googletagmanager.com https://www.google-analytics.com; script-src 'self' 'unsafe-inline' https://www.googletagmanager.com https://tagmanager.google.com https://www.google-analytics.com https://ssl.google-analytics.com; connect-src https://www.google-analytics.com; font-src fonts.gstatic.com; style-src 'self' 'unsafe-inline' fonts.googleapis.com https://tagmanager.google.com; object-src 'none'"
  forwarded_headers                   = ["Authorization", "Referer", "User-Agent"]
}

# BaT Buyer UI
module "cloudfront_bat_client" {
  source                              = "./cloudfront"
  aws_account_id                      = var.aws_account_id
  environment                         = var.environment
  cloudfront_s3_log_retention_in_days = var.cloudfront_s3_log_retention_in_days
  hosted_zone_name_alb                = data.aws_ssm_parameter.hosted_zone_name_alb_bat_client.value
  hosted_zone_name_cdn                = data.aws_ssm_parameter.hosted_zone_name_cdn_bat_client.value
  resource_label                      = "bat-client"
  cache_default_ttl                   = 0
  cache_max_ttl                       = 0
  // Image source requires CCS and S3 domains as BaT product images are loaded via a redirect to an S3 pre-signed URL
  content_security_policy = "default-src 'none'; img-src 'self' *.crowncommercial.gov.uk *.s3.eu-west-2.amazonaws.com; script-src 'self' 'unsafe-inline'; font-src fonts.gstatic.com; style-src 'self' 'unsafe-inline' fonts.googleapis.com; object-src 'none'"
  forwarded_headers       = ["Authorization", "Referer", "User-Agent"]
}

module "cloudfront_bat_backend" {
  source                              = "./cloudfront"
  aws_account_id                      = var.aws_account_id
  environment                         = var.environment
  cloudfront_s3_log_retention_in_days = var.cloudfront_s3_log_retention_in_days
  hosted_zone_name_alb                = data.aws_ssm_parameter.hosted_zone_name_alb_bat_backend.value
  hosted_zone_name_cdn                = data.aws_ssm_parameter.hosted_zone_name_cdn_bat_backend.value
  resource_label                      = "bat-backend"
  cache_default_ttl                   = 0
  cache_max_ttl                       = 0
  // Image source requires CCS and S3 domains as BaT product images are loaded via a redirect to an S3 pre-signed URL
  content_security_policy = "default-src 'none'; img-src 'self' *.crowncommercial.gov.uk *.s3.eu-west-2.amazonaws.com data:; script-src 'self' 'unsafe-inline' js-agent.newrelic.com bam.eu01.nr-data.net; font-src 'self' fonts.gstatic.com; style-src 'self' 'unsafe-inline' fonts.googleapis.com; object-src 'unsafe-inline'; connect-src 'self' bam.eu01.nr-data.net"
  forwarded_headers       = ["Authorization", "Referer", "User-Agent", "Accept"]

}


