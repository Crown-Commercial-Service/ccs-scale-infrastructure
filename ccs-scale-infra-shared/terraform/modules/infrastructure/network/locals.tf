locals {
  network_acls = {
    "vpc_database" = {
      protocol   = "tcp"
      rule_no    = 10
      action     = "allow"
      cidr_block = data.aws_vpc.scale.cidr_block
      from_port  = 5432
      to_port    = 5432
      egress     = false
    },
    "neo4J" = {
      protocol   = "tcp"
      rule_no    = 20
      action     = "allow"
      cidr_block = data.aws_vpc.scale.cidr_block
      from_port  = 7687
      to_port    = 7687
      egress     = false
    },
    "inbound_from_ECR" = {
      protocol   = "tcp"
      rule_no    = 30
      action     = "allow"
      cidr_block = data.aws_vpc.scale.cidr_block
      from_port  = var.https_port
      to_port    = var.https_port
      egress     = false
    },
    "ephemeral_inbound_for_responses_from_internal" = {
      protocol   = "tcp"
      rule_no    = 40
      action     = "allow"
      cidr_block = data.aws_vpc.scale.cidr_block
      from_port  = 1024
      to_port    = 65535
      egress     = false
    },
    "ephemeral_inbound_for_responses_from_internet" = {
      protocol   = "tcp"
      rule_no    = 50
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 1024
      to_port    = 65535
      egress     = false
    },
    "outbound_https_to_vpc" = {
      protocol   = "tcp"
      rule_no    = 60
      action     = "allow"
      cidr_block = data.aws_vpc.scale.cidr_block
      from_port  = 443
      to_port    = 443
      egress     = true
    },
    "outbound_https_to_internet" = {
      protocol   = "tcp"
      rule_no    = 70
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 443
      to_port    = 443
      egress     = true
    },
    "outbound_ephmeral_from_responses_intenral" = {
      protocol   = "tcp"
      rule_no    = 80
      action     = "allow"
      cidr_block = data.aws_vpc.scale.cidr_block
      from_port  = 1024
      to_port    = 65535
      egress     = true
    }
  }
}
