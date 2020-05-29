variable "aws_account_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "public_web_subnet_ids" {
  type = list(string)
}

variable "private_app_subnet_ids" {
  type = list(string)
}

variable "private_db_subnet_ids" {
  type = list(string)
}
