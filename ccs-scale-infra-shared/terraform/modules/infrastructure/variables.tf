variable "aws_account_id" {
  type = string
}

variable "cidr_blocks_allowed_external" {
  type = list(string)
}

variable "ec2_key_pair" {
  type    = string
  default = "ccs-spree-key"
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_app_subnet_ids" {
  type = list(string)
}

variable "public_web_subnet_ids" {
  type = list(string)
}

variable "private_db_subnet_ids" {
  type = list(string)
}

variable "cloudfront_s3_log_retention_in_days" {
  type = number
}

variable "transit_gateway_networks" {
  description = "Transit gateway routes"
  type = map(object({
    cidr_block  = string
    rule_number = number
  }))
  default = {}
}

