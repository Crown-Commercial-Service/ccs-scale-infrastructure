variable "environment" {
  type = string
}

variable "lb_private_arn" {
  type = string
}

variable "lb_private_db_arn" {
  type = string
}

variable "lb_public_arn" {
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

variable "scale_rest_api_id" {
  type = string
}

variable "scale_rest_execution_arn" {
  type = string
}

variable "scale_rest_parent_resource_id" {
  type = string
}
