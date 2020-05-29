provider "aws" {
  profile = "default"
  region  = "eu-west-2"

  assume_role {
    role_arn = "arn:aws:iam::${var.aws_account_id}:role/CCS_SCALE_Build"
  }
}

module "network" {
  source                 = "./network"
  environment            = var.environment
  vpc_id                 = var.vpc_id
  private_app_subnet_ids = var.private_app_subnet_ids
  public_web_subnet_ids  = var.public_web_subnet_ids
  ecr_access_cidr_blocks = var.ecr_access_cidr_blocks
  eip_id_nat             = var.eip_id_nat
  eip_id_nlb             = var.eip_id_nlb
}

#module "ecs" {
#  source      = "./ecs"
#  vpc_id      = var.vpc_id
#  environment = var.environment
#}

##module "api" {
#  source      = "./api"
#  environment = var.environment
#}
