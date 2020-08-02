/*
 * VPC outputs
 */
output "lb_private_arn" {
  value = module.network.lb_private_arn
}

output "lb_private_db_arn" {
  value = module.network.lb_private_db_arn
}

output "lb_public_arn" {
  value = module.network.lb_public_arn
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

output "cloudfront_id" {
  value = module.cloudfront.cloudfront_id
}

output "lb_public_alb_listner_arn" {
  value = module.network.lb_public_alb_listner_arn
}


/*
output "target_group_9000_arn" {
  value = module.network.target_group_9000_arn
}


output "target_group_9020_arn" {
  value = module.network.target_group_9020_arn
}

output "target_group_9030_arn" {
  value = module.network.target_group_9030_arn
}
*/

/*
 * ECS outputs
 */
/*
output "ecs_security_group_id" {
  value = module.ecs.ecs_security_group_id
}

output "ecs_task_execution_arn" {
  value = module.ecs.ecs_task_execution_arn
}

output "ecs_cluster_id" {
  value = module.ecs.ecs_cluster_id
}
*/

/*
 * API outputs
 */
/*
output "scale_rest_api_id" {
  value = module.api.scale_rest_api_id
}

output "scale_rest_api_execution_arn" {
  value = module.api.scale_rest_api_execution_arn
}

output "parent_resource_id" {
  value = module.api.parent_resource_id
}
*/
