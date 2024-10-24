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

variable "cidr_blocks_allowed_external" {
  type = list
}

variable "ansible_tower_cidr_block" {
  type = list(string)
}

variable "jumar_vpn_cidr_block" {
  type = list(string)
}
