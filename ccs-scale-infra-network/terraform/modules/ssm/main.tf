##########################################################
# Infrastructure: SSM Parameters
#
# Creates Parameters used by other infra scripts
##########################################################
provider "aws" {
  profile = "default"
  region  = "eu-west-2"

  assume_role {
    role_arn = "arn:aws:iam::${var.aws_account_id}:role/CCS_SCALE_Build"
  }
}

resource "aws_ssm_parameter" "vpc_id" {
  name  = "${lower(var.environment)}-vpc-id"
  type  = "String"
  value = var.vpc_id
}

resource "aws_ssm_parameter" "public_web_subnet_ids" {
  name  = "${lower(var.environment)}-public-web-subnet-ids"
  type  = "String"
  value = join(",", var.public_web_subnet_ids)
}

resource "aws_ssm_parameter" "private_app_subnet_ids" {
  name  = "${lower(var.environment)}-private-app-subnet-ids"
  type  = "String"
  value = join(",", var.private_app_subnet_ids)
}

resource "aws_ssm_parameter" "private_db_subnet_ids" {
  name  = "${lower(var.environment)}-private-db-subnet-ids"
  type  = "String"
  value = join(",", var.private_db_subnet_ids)
}
