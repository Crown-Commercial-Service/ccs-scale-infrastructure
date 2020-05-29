##################
# Global variables
##################
locals {
  env_accounts = {
    mgmt = "016776319009"
  }
}

output "env_accounts" {
  value = local.env_accounts
}

output "allowed_cors_headers" {
  value = [
    "Authorization",
    "Content-Type",
    "X-Amz-Date",
    "X-Amz-Security-Token",
    "X-Api-Key",
    "Access-Control-Request-Headers",
    "Access-Control-Request-Method"
  ]
}

output "project_name" {
  value = "SCALE"
}

output "project_cost_code" {
  value = "PR2-00001"
}
