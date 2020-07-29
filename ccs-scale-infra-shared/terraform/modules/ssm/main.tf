##########################################################
# Infrastructure: SSM Parameters
#
# Creates Parameters used by other infra scripts
##########################################################

resource "aws_ssm_parameter" "lb_private_arn" {
  name      = "${lower(var.environment)}-lb-private-arn"
  type      = "String"
  value     = var.lb_private_arn
  overwrite = true
}

resource "aws_ssm_parameter" "lb_private_db_arn" {
  name      = "${lower(var.environment)}-lb-private-db-arn"
  type      = "String"
  value     = var.lb_private_db_arn
  overwrite = true
}

resource "aws_ssm_parameter" "lb_public_arn" {
  name      = "${lower(var.environment)}-lb-public-arn"
  type      = "String"
  value     = var.lb_public_arn
  overwrite = true
}

resource "aws_ssm_parameter" "lb_public_alb_arn" {
  name      = "${lower(var.environment)}-lb-public-alb-arn"
  type      = "String"
  value     = var.lb_public_alb_arn
  overwrite = true
}

resource "aws_ssm_parameter" "vpc_link_id" {
  name      = "${lower(var.environment)}-vpc-link-id"
  type      = "String"
  value     = var.vpc_link_id
  overwrite = true
}

resource "aws_ssm_parameter" "lb_private_dns" {
  name      = "${lower(var.environment)}-lb-private-dns"
  type      = "String"
  value     = var.lb_private_dns
  overwrite = true
}

resource "aws_ssm_parameter" "lb_private_db_dns" {
  name      = "${lower(var.environment)}-lb-private-db-dns"
  type      = "String"
  value     = var.lb_private_db_dns
  overwrite = true
}

resource "aws_ssm_parameter" "cloudfront_id" {
  name      = "${lower(var.environment)}-cloudfront-id"
  type      = "SecureString"
  value     = var.cloudfront_id
  overwrite = true
}
