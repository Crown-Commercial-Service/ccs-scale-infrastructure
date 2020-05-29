output "scale_rest_api_id" {
  value = aws_api_gateway_rest_api.scale.id
}

output "scale_rest_api_execution_arn" {
  value = aws_api_gateway_rest_api.scale.execution_arn
}

output "parent_resource_id" {
  value = aws_api_gateway_resource.scale.id
}
