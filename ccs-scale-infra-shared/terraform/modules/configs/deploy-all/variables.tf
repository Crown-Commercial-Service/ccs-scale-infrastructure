variable "aws_account_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "cloudtrail_cw_log_retention_in_days" {
  type    = number
  default = 1
}

variable "cloudtrail_s3_log_retention_in_days" {
  type    = number
  default = 1
}

variable "cloudwatch_s3_force_destroy" {
  type    = bool
  default = true
}

variable "cloudfront_s3_log_retention_in_days" {
  type    = number
  default = 7
}

variable "transit_gateway_routes" {
  description = "Transit gateway routes"
  type = map(object({
    destination_cidr_block = string
    transit_gateway_id     = string
  }))
  default = {}
}
