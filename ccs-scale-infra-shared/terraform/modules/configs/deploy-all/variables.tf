variable "aws_account_id" {
  type = string
}

variable "environment" {
  type = string
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
