variable "aws_account_id" {
  type = string
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

variable "ecr_access_cidr_blocks" {
  type = list(string)
}

variable "eip_id_nat" {
  type = string
}

variable "eip_id_nlb" {
  type = string
}
