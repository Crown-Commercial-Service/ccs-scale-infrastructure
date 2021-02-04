/*
 * VPC outputs
 */
output "lb_private_arn" {
  value = module.network.lb_private_arn
}

output "lb_private_db_arn" {
  value = module.network.lb_private_db_arn
}

output "lb_public_alb_arn" {
  value = module.network.lb_public_alb_arn
}

output "vpc_link_id" {
  value = module.network.vpc_link_id
}

output "lb_private_dns" {
  value = module.network.lb_private_dns
}

output "lb_private_db_dns" {
  value = module.network.lb_private_db_dns
}
