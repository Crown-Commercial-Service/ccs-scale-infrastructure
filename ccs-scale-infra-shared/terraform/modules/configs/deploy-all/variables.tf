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

variable "logitio_port" {
  type = number

  # Default logit.io TCP port (use as default for all envs unless overridden)
  default = 21976
}

variable "kali_instance" {
  type    = bool
  default = false
}

variable "kali_instance_type" {
  type    = string
  default = "t2.micro"
}
