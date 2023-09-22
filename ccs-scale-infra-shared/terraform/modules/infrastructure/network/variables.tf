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
  type = list(any)
}

variable "public_nlb_eip_ids" {
  type = list(any)
}

variable "transit_gateway_routes" {
  description = "Transit gateway routes"
  type = map(object({
    destination_cidr_block = string
    transit_gateway_id     = string
    rule_number            = number
  }))
  default = {}
}
