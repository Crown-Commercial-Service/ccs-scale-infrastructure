variable "cidr_blocks_allowed_external" {
  type = list(string)
}

variable "environment" {
  type = string
}

variable "http_port" {
  default = 80
}

variable "https_port" {
  default = 443
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

variable "private_db_subnet_ids" {
  type = list(string)
}

variable "nat_eip_ids" {
  type = list
}

variable "public_nlb_eip_ids" {
  type = list
}
