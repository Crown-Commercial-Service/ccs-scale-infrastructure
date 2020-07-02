##############################################################
# VPC Endpoints (AWS PrivateLink)
#
# These allow private communication between instances or
# containers within the VPC to ECR, ECS and S3 services without
# the need for Internet and NAT Gateway components.
#
##############################################################

module "globals" {
  source = "../../globals"
}

resource "aws_vpc_endpoint" "vpc_endpoint_ecr" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.eu-west-2.ecr.dkr"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.allow_inbound_https.id
  ]

  # Set to whichever subnet group spans the most AZs
  subnet_ids          = var.private_db_subnet_ids
  private_dns_enabled = true

  tags = {
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "NETWORK"
  }
}

resource "aws_vpc_endpoint" "vpc_endpoint_cloudwatch" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.eu-west-2.logs"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.allow_inbound_https.id
  ]

  # Set to whichever subnet group spans the most AZs
  subnet_ids          = var.private_db_subnet_ids
  private_dns_enabled = true

  tags = {
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "NETWORK"
  }
}

resource "aws_vpc_endpoint" "vpc_endpoint_s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.eu-west-2.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.scale_main.id,
    aws_route_table.scale_ig.id
  ]

  tags = {
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "NETWORK"
  }
}

resource "aws_security_group" "allow_inbound_https" {
  name        = "vpc_endpoint_ecr_allow_https"
  description = "Allow HTTPS inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.ecr_access_cidr_blocks
  }

  tags = {
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "NETWORK"
  }
}

##############################################################
# VPC Access control list
##############################################################

resource "aws_network_acl" "scale" {
  vpc_id     = var.vpc_id
  subnet_ids = var.private_app_subnet_ids

  tags = {
    Name        = "SCALE:EU2:${upper(var.environment)}:VPC:ACL"
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "NETWORK"
  }
}

resource "aws_network_acl_rule" "ingress_http" {
  network_acl_id = aws_network_acl.scale.id
  egress         = false
  from_port      = 80
  to_port        = 80
  rule_number    = 100
  rule_action    = "allow"
  protocol       = "tcp"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "ingress_https" {
  network_acl_id = aws_network_acl.scale.id
  egress         = false
  from_port      = 443
  to_port        = 443
  rule_number    = 110
  rule_action    = "allow"
  protocol       = "tcp"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "ingress_http_9000" {
  network_acl_id = aws_network_acl.scale.id
  egress         = false
  from_port      = 9000
  to_port        = 9000
  rule_number    = 130
  rule_action    = "allow"
  protocol       = "tcp"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "ingress_http_9010" {
  network_acl_id = aws_network_acl.scale.id
  egress         = false
  from_port      = 9010
  to_port        = 9010
  rule_number    = 140
  rule_action    = "allow"
  protocol       = "tcp"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "ingress_http_9030" {
  network_acl_id = aws_network_acl.scale.id
  egress         = false
  from_port      = 9030
  to_port        = 9030
  rule_number    = 150
  rule_action    = "allow"
  protocol       = "tcp"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "egress_http" {
  network_acl_id = aws_network_acl.scale.id
  egress         = true
  from_port      = var.http_port
  to_port        = var.http_port
  rule_number    = 160
  rule_action    = "allow"
  protocol       = "tcp"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "egress_https" {
  network_acl_id = aws_network_acl.scale.id
  egress         = true
  from_port      = var.https_port
  to_port        = var.https_port
  rule_number    = 170
  rule_action    = "allow"
  protocol       = "tcp"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "ingress_ephemeral" {
  network_acl_id = aws_network_acl.scale.id
  egress         = false
  from_port      = 1024
  to_port        = 65535
  rule_number    = 200
  rule_action    = "allow"
  protocol       = "tcp"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "egress_ephemeral" {
  network_acl_id = aws_network_acl.scale.id
  egress         = true
  from_port      = 1024
  to_port        = 65535
  rule_number    = 210
  rule_action    = "allow"
  protocol       = "tcp"
  cidr_block     = "0.0.0.0/0"
}

##############################################################
# Internet Gateway
##############################################################

resource "aws_internet_gateway" "scale" {
  vpc_id = var.vpc_id

  tags = {
    Name        = "SCALE:EU2:${upper(var.environment)}:IGW:EXT"
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "NETWORK"
  }
}

##############################################################
# NAT Gateway for private subnets outbound traffic
# Availability Zone A only at the moment (no redundancy)
##############################################################

# Provide a datasource to obtain the subnet's AZ ID for NAT naming
data "aws_subnet" "public" {
  for_each = toset(var.public_web_subnet_ids)

  id = each.value
}

resource "aws_nat_gateway" "scale" {
  count = length(var.public_web_subnet_ids)

  allocation_id = var.nat_eip_ids[count.index]
  subnet_id     = var.public_web_subnet_ids[count.index]
  depends_on    = [aws_internet_gateway.scale]

  tags = {
    Name        = "SCALE:EU2:${upper(var.environment)}:NAT:${upper(data.aws_subnet.public["${var.public_web_subnet_ids[count.index]}"].availability_zone)}"
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "NETWORK"
  }
}

##############################################################
# Routing Tables
##############################################################

resource "aws_route_table" "scale_main" {
  vpc_id = var.vpc_id

  tags = {
    Name        = "SCALE:EU2:${upper(var.environment)}:RT:EXT"
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "NETWORK"
  }
}

resource "aws_main_route_table_association" "scale_main" {
  vpc_id         = var.vpc_id
  route_table_id = aws_route_table.scale_main.id
}

resource "aws_route_table" "scale_ig" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.scale.id
  }

  tags = {
    Name        = "SCALE:EU2:${upper(var.environment)}:RT:IGW"
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "NETWORK"
  }
}

resource "aws_route_table" "scale_nat" {
  vpc_id = var.vpc_id

  # Cannot reference the NAT resource as it hasn't been
  dynamic "route" {
    # for_each = var.public_web_subnet_ids
    for_each = aws_nat_gateway.scale
    iterator = nat_gateway

    content {
      cidr_block = "0.0.0.0/0"
      # nat_gateway_id = aws_nat_gateway.scale[route.key].id
      nat_gateway_id = nat_gateway.value.id
    }
  }

  tags = {
    Name        = "SCALE:EU2:${upper(var.environment)}:RT:NAT"
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "NETWORK"
  }
}

##############################################################
# Routing Table/Subnet associations - Internet Gateway access
##############################################################

# TODO: Provision multiple based on AZ (subnet) config
resource "aws_route_table_association" "scale_ig" {
  for_each = toset(var.public_web_subnet_ids)

  route_table_id = aws_route_table.scale_ig.id
  subnet_id      = each.value
}

##############################################################
# Routing Table/Subnet associations - outbound access via NAT Gateway
##############################################################

# TODO: Provision multiple based on AZ (subnet) config
resource "aws_route_table_association" "scale_nat" {
  for_each = toset(var.private_app_subnet_ids)

  route_table_id = aws_route_table.scale_nat.id
  subnet_id      = each.value
}

##############################################################
# Routing Table/Subnet associations - no external access
##############################################################

# None

##############################################################
# DNS Zones
##############################################################
# data "aws_route53_zone" "public_cluster_https_domain" {
#   name         = var.domain_name
#   private_zone = false
# }
#
# resource "aws_route53_zone" "SCALE-internal-org-private" {
#   name    = "${var.domain_internal_prefix}.${var.domain_name}"
#   comment = "Internal DNS for SCALE VPC"
#   vpc {
#     vpc_id     = aws_vpc.SCALE-Services.id
#     vpc_region = "eu-west-2"
#   }
#
#   tags = {
#     Name             = "Internal DNS for SCALE VPC"
#     SCALERole        = "Infrastructure"
#     SCALEEnvironment = var.environment_name
#   }
# }
#
# resource "aws_route53_zone" "SCALE-internal-org-public" {
#   count   = 1
#   name    = "${var.domain_internal_prefix}.${var.domain_name}"
#   comment = "Public DNS for SCALE VPC"
#
#   tags = {
#     Name             = "Public DNS for SCALE VPC"
#     SCALERole        = "Infrastructure"
#     SCALEEnvironment = var.environment_name
#   }
# }
#
# resource "aws_route53_record" "SCALE-internal-org-public-ns" {
#   count   = 1
#   zone_id = data.aws_route53_zone.public_cluster_https_domain.zone_id
#   name    = "${var.domain_internal_prefix}.${var.domain_name}"
#   type    = "NS"
#   ttl     = "60"
#
#   records = [
#     aws_route53_zone.SCALE-internal-org-public.0.name_servers.0,
#     aws_route53_zone.SCALE-internal-org-public.0.name_servers.1,
#     aws_route53_zone.SCALE-internal-org-public.0.name_servers.2,
#     aws_route53_zone.SCALE-internal-org-public.0.name_servers.3,
#   ]
# }
