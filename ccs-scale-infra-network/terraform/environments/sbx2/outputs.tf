output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_web_subnet_ids" {
  value = module.vpc.public_web_subnet_ids
}

output "private_app_subnet_ids" {
  value = module.vpc.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  value = module.vpc.private_db_subnet_ids
}
