variable "aws_account_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "force_destroy_cloudfront_logs_bucket" {
  type    = bool
  default = true
}

variable "cloudfront_s3_log_retention_in_days" {
  type = number
}
variable "hosted_zone_name_alb" {
  type = string
}

variable "hosted_zone_name_cdn" {
  type = string
}

variable "resource_label" {
  type = string
}

variable "cache_default_ttl" {
  type = number
}

variable "cache_max_ttl" {
  type = number
}
