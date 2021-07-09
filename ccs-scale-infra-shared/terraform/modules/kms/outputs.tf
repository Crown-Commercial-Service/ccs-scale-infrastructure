output "cloudtrail_kms_key_arn" {
  value = aws_kms_key.cloudtrail.arn
}

output "cloudwatch_kms_key_arn" {
  value = aws_kms_key.cloudwatch.arn
}
