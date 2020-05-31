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

variable "ecr_access_cidr_blocks" {
  type = list(string)
}

variable "eip_id_nat" {
  type = string
}

variable "eip_id_nlb" {
  type = string
}
