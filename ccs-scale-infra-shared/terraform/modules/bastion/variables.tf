variable "vpc_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "db_cidr_blocks" {
  type = list(string)
}

variable "bastion_kms_key_id" {
  type = string
}
