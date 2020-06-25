variable "environment" {
  type = string
}

variable "lb_public_dns" {
  type = string
}

variable "force_destroy_cloudfront_logs_bucket" {
  type    = bool
  default = true
}
