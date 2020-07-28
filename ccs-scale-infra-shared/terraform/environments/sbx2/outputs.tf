output "lb_private_arn" {
  value = module.deploy.lb_private_arn
}

output "lb_public_arn" {
  value = module.deploy.lb_public_arn
}

output "lb_public_alb_arn" {
  value = module.deploy.lb_public_alb_arn
}

output "vpc_link_id" {
  value = module.deploy.vpc_link_id
}

output "lb_private_dns" {
  value = module.deploy.lb_private_dns
}
