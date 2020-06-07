variable "aws_account_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "cidr_block_vpc" {
  type = string
}

variable "subnet_configs" {
  type = map
}
