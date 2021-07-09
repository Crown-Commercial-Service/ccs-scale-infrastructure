variable "aws_account_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "cloudtrail_cw_log_retention_in_days" {
  type = number
}

variable "cloudtrail_s3_log_retention_in_days" {
  type = number
}

variable "cloudwatch_s3_force_destroy" {
  type = bool
}

variable "cloudtrail_kms_key_arn" {
  type = string
}
