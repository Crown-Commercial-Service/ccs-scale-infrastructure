variable "aws_account_id" {
  type = string
}

variable "lambda_edge_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type = string
}

variable "resource_label" {
  type = string
}

variable "content_security_policy" {
  type = string
}
