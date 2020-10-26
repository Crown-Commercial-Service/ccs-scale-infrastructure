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

data "aws_vpc" "scale" {
  id = var.vpc_id
}

##############################################################
# VPC Endpoints (AWS PrivateLink)
#
# These allow private communication between instances or
# containers within the VPC to ECR, ECS, S3, CW and API gateway
# services without the need for traffic to route via the Internet
#
##############################################################
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
    Name        = "SCALE:EU2:${upper(var.environment)}:VPC:ENDPOINT-ECR"
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "NETWORK"
  }
}

resource "aws_vpc_endpoint" "api_gateway" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.eu-west-2.execute-api"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.allow_inbound_https.id
  ]

  # Set to whichever subnet group spans the most AZs
  subnet_ids          = var.private_db_subnet_ids
  private_dns_enabled = true

  tags = {
    Name        = "SCALE:EU2:${upper(var.environment)}:VPC:ENDPOINT-APIG"
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
    Name        = "SCALE:EU2:${upper(var.environment)}:VPC:ENDPOINT-CW"
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
    Name        = "SCALE:EU2:${upper(var.environment)}:VPC:ENDPOINT-S3"
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
    cidr_blocks = [data.aws_vpc.scale.cidr_block]
  }

  tags = {
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "NETWORK"
  }
}

##############################################################
# VPC Access control lists - one for each subnet group (public, private, database)
##############################################################

resource "aws_network_acl" "scale_external" {
  vpc_id     = var.vpc_id
  subnet_ids = var.public_web_subnet_ids

  # Allow all inbound traffic on the external load balancer listener port
  ingress {
    protocol   = "tcp"
    rule_no    = 10
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = var.https_port
    to_port    = var.https_port
  }

  # Allow inbound traffic to NAT from instances within the VPC
  ingress {
    protocol   = "tcp"
    rule_no    = 20
    action     = "allow"
    cidr_block = data.aws_vpc.scale.cidr_block
    from_port  = var.https_port
    to_port    = var.https_port
  }

  # Allow all inbound traffic on the NAT G/W ephemeral ports
  ingress {
    protocol   = "tcp"
    rule_no    = 30
    action     = "allow"
    cidr_block = "0.0.0.0/0" # CCS range?
    from_port  = 1024
    to_port    = 65535
  }

  # Allow all inbound traffic on the SSH port (Bastion host)
  ingress {
    protocol   = "tcp"
    rule_no    = 40
    action     = "allow"
    cidr_block = "0.0.0.0/0" # CCS range?
    from_port  = 22
    to_port    = 22
  }

  # Allow outbound traffic to the VPC on port 443
  egress {
    protocol   = "tcp"
    rule_no    = 50
    action     = "allow"
    cidr_block = data.aws_vpc.scale.cidr_block
    from_port  = var.http_port
    to_port    = var.http_port
  }

  # Allow outbound traffic to the VPC on instance/health check ports
  # Buyer UI only
  egress {
    protocol   = "tcp"
    rule_no    = 60
    action     = "allow"
    cidr_block = data.aws_vpc.scale.cidr_block
    from_port  = 9030
    to_port    = 9030
  }

  # Allow all outbound traffic on the ephemeral ports (for responses)
  egress {
    protocol   = "tcp"
    rule_no    = 70
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow all outbound traffic on port 443 (from Buyer UI via NAT Gateway to CCS)
  egress {
    protocol   = "tcp"
    rule_no    = 80
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Allow outbound traffic to the internet on port 443
  egress {
    protocol   = "tcp"
    rule_no    = 90
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  tags = {
    Name        = "SCALE:EU2:${upper(var.environment)}:VPC:ACL-EXTERNAL"
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "NETWORK"
  }
}

resource "aws_network_acl" "scale_internal" {
  vpc_id     = var.vpc_id
  subnet_ids = var.private_app_subnet_ids

  # Allow inbound traffic from the VPC on the instance+health check ports
  # Decision Tree Service
  ingress {
    protocol   = "tcp"
    rule_no    = 10
    action     = "allow"
    cidr_block = data.aws_vpc.scale.cidr_block
    from_port  = 9000
    to_port    = 9000
  }

  # Agreements Service
  ingress {
    protocol   = "tcp"
    rule_no    = 20
    action     = "allow"
    cidr_block = data.aws_vpc.scale.cidr_block
    from_port  = 9010
    to_port    = 9010
  }

  # Guided Match Service
  ingress {
    protocol   = "tcp"
    rule_no    = 30
    action     = "allow"
    cidr_block = data.aws_vpc.scale.cidr_block
    from_port  = 9020
    to_port    = 9020
  }

  # Buyer UI
  ingress {
    protocol   = "tcp"
    rule_no    = 40
    action     = "allow"
    cidr_block = data.aws_vpc.scale.cidr_block
    from_port  = 9030
    to_port    = 9030
  }

  # Spree Backend NLB listener
  ingress {
    protocol   = "tcp"
    rule_no    = 41
    action     = "allow"
    cidr_block = data.aws_vpc.scale.cidr_block
    from_port  = 80
    to_port    = 80
  }

  #Allow inbound traffic from the VPC on port 443 for VPC Link / other AWS services
  ingress {
    protocol   = "tcp"
    rule_no    = 50
    action     = "allow"
    cidr_block = data.aws_vpc.scale.cidr_block
    from_port  = var.https_port
    to_port    = var.https_port
  }

  # Allow inbound internet traffic on the ephemeral ports (for responses)
  ingress {
    protocol   = "tcp"
    rule_no    = 60
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow outbound VPC traffic on the ephemeral ports for responses to internal services
  egress {
    protocol   = "tcp"
    rule_no    = 70
    action     = "allow"
    cidr_block = data.aws_vpc.scale.cidr_block
    from_port  = 1024
    to_port    = 65535
  }

  # Allow outbound internet traffic on port 443 (Buyer UI -> NAT / ECR)
  egress {
    protocol   = "tcp"
    rule_no    = 80
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  tags = {
    Name        = "SCALE:EU2:${upper(var.environment)}:VPC:ACL-INTERNAL"
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "NETWORK"
  }
}

resource "aws_network_acl" "scale_database" {
  vpc_id     = var.vpc_id
  subnet_ids = var.private_db_subnet_ids

  # Allow traffic from the VPC to database ports
  # Postgres
  ingress {
    protocol   = "tcp"
    rule_no    = 10
    action     = "allow"
    cidr_block = data.aws_vpc.scale.cidr_block
    from_port  = 5432
    to_port    = 5432
  }

  # Neo4J
  ingress {
    protocol   = "tcp"
    rule_no    = 20
    action     = "allow"
    cidr_block = data.aws_vpc.scale.cidr_block
    from_port  = 7687
    to_port    = 7687
  }

  # Inbound from ECR / other AWS services
  ingress {
    protocol   = "tcp"
    rule_no    = 30
    action     = "allow"
    cidr_block = data.aws_vpc.scale.cidr_block
    from_port  = var.https_port
    to_port    = var.https_port
  }

  # Allow inbound traffic from VPC on ephemeral ports for responses from internal / external services
  ingress {
    protocol   = "tcp"
    rule_no    = 40
    action     = "allow"
    cidr_block = data.aws_vpc.scale.cidr_block
    from_port  = 1024
    to_port    = 65535
  }

  # Allow inbound internet traffic on the ephemeral ports (for responses)
  ingress {
    protocol   = "tcp"
    rule_no    = 50
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow outbound traffic to the VPC on port 443 (ECR)
  egress {
    protocol   = "tcp"
    rule_no    = 60
    action     = "allow"
    cidr_block = data.aws_vpc.scale.cidr_block
    from_port  = 443
    to_port    = 443
  }

  # Allow outbound internet traffic on port 443 (ECR)
  egress {
    protocol   = "tcp"
    rule_no    = 70
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Allow outbound traffic to the VPC on the ephemeral ports for responses to internal services
  egress {
    protocol   = "tcp"
    rule_no    = 80
    action     = "allow"
    cidr_block = data.aws_vpc.scale.cidr_block
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name        = "SCALE:EU2:${upper(var.environment)}:VPC:ACL-DB"
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "NETWORK"
  }
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
  count = length(var.public_web_subnet_ids)

  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.scale[count.index].id
  }

  tags = {
    Name        = "SCALE:EU2:${upper(var.environment)}:RT:NAT:${upper(data.aws_subnet.public["${var.public_web_subnet_ids[count.index]}"].availability_zone)}"
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "NETWORK"
  }
}

##############################################################
# Routing Table/Subnet associations - Internet Gateway access
##############################################################

resource "aws_route_table_association" "scale_ig" {
  for_each = toset(var.public_web_subnet_ids)

  route_table_id = aws_route_table.scale_ig.id
  subnet_id      = each.value
}

##############################################################
# Routing Table/Subnet associations - outbound access via NAT Gateway
##############################################################

resource "aws_route_table_association" "scale_nat" {
  count = length(var.private_app_subnet_ids)

  route_table_id = aws_route_table.scale_nat[count.index].id
  subnet_id      = var.private_app_subnet_ids[count.index]
}

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
