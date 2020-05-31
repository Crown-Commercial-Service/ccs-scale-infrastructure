##########################################################
# Infrastructure: VPC & Subnets
#
# Creates VPC, public (WEB) and private (APP & DB) subnets
##########################################################

provider "aws" {
  profile = "default"
  region  = "eu-west-2"

  assume_role {
    role_arn = "arn:aws:iam::${var.aws_account_id}:role/CCS_SCALE_Build"
  }
}

module "globals" {
  source = "../globals"
}

##############################################################
# VPC
##############################################################
resource "aws_vpc" "SCALE-Services" {
  cidr_block           = var.cidr_block_vpc
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = {
    Name        = "SCALE:EU2:${upper(var.environment)}:VPC"
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "NETWORK"
  }
}

##############################################################
# Public Subnets
##############################################################
resource "aws_subnet" "SCALE-AZ-WEB-Public" {
  for_each = var.subnet_configs["public_web"]

  vpc_id            = aws_vpc.SCALE-Services.id
  cidr_block        = each.value["cidr_block"]
  availability_zone = each.key
  map_public_ip_on_launch = true

  tags = {
    Name        = "SCALE:EU2:${upper(var.environment)}:WEB:${upper(each.value["az_id"])}:SUBNET"
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "NETWORK"
  }
}

##############################################################
# Private Subnets - APP
##############################################################
resource "aws_subnet" "SCALE-AZ-APP-Private" {
  for_each = var.subnet_configs["private_app"]

  vpc_id                  = aws_vpc.SCALE-Services.id
  cidr_block              = each.value["cidr_block"]
  availability_zone       = each.key
  map_public_ip_on_launch = false

  tags = {
    Name        = "SCALE:EU2:${upper(var.environment)}:APP:${upper(each.value["az_id"])}:SUBNET"
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "NETWORK"
  }
}

##############################################################
# Private Subnets - DB
##############################################################
resource "aws_subnet" "SCALE-AZ-DB-Private" {
  for_each = var.subnet_configs["private_db"]

  vpc_id                  = aws_vpc.SCALE-Services.id
  cidr_block              = each.value["cidr_block"]
  availability_zone       = each.key
  map_public_ip_on_launch = false

  tags = {
    Name        = "SCALE:EU2:${upper(var.environment)}:DB:${upper(each.value["az_id"])}:SUBNET"
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "NETWORK"
  }
}
