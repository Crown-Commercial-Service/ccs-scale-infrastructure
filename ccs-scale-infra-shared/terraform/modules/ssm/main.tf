##########################################################
# Infrastructure: SSM Parameters
#
# Creates Parameters used by other infra scripts
##########################################################

resource "aws_ssm_parameter" "lb_private_arn" {
  name  = "${lower(var.environment)}-lb-private-arn"
  type  = "String"
  value = var.lb_private_arn
}

resource "aws_ssm_parameter" "lb_private_db_arn" {
  name  = "${lower(var.environment)}-lb-private-db-arn"
  type  = "String"
  value = var.lb_private_db_arn
}

resource "aws_ssm_parameter" "lb_public_arn" {
  name  = "${lower(var.environment)}-lb-public-arn"
  type  = "String"
  value = var.lb_public_arn
}

resource "aws_ssm_parameter" "vpc_link_id" {
  name  = "${lower(var.environment)}-vpc-link-id"
  type  = "String"
  value = var.vpc_link_id
}

resource "aws_ssm_parameter" "lb_private_dns" {
  name  = "${lower(var.environment)}-lb-private-dns"
  type  = "String"
  value = var.lb_private_dns
}

resource "aws_ssm_parameter" "lb_private_db_dns" {
  name  = "${lower(var.environment)}-lb-private-db-dns"
  type  = "String"
  value = var.lb_private_db_dns
}
