output "add_security_headers_function_qarn" {
  value = aws_lambda_function.security_headers.qualified_arn
}
