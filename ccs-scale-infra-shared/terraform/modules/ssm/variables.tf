variable "environment" {
  type = string
}

variable "lb_private_arn" {
  type = string
}

variable "lb_private_db_arn" {
  type = string
}

variable "lb_public_alb_arn" {
  type = string
}

variable "vpc_link_id" {
  type = string
}

variable "lb_private_dns" {
  type = string
}

variable "lb_private_db_dns" {
  type = string
}

variable "cloudwatch_kms_key_arn" {
  type = string
}
