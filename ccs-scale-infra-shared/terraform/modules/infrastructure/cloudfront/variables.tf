variable "aws_account_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "lb_public_dns" {
  type = string
}

variable "lb_public_alb_dns" {
  type = string
}

variable "force_destroy_cloudfront_logs_bucket" {
  type    = bool
  default = true
}
