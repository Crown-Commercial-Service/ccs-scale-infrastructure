##############################################################
#
# SCALE Load Balancers
#
# Creat an internal NLB for API traffic from Scale API Gateway into private subnets
# Creat an external NLB for traffic originating from outside Scale
# (i.e. to the Buyer UI from the internet)
#
# Targets in Target Group are created by each service
#
# Each service needs to be deployed on a different port
#
##############################################################

resource "aws_lb" "private" {
  name               = "SCALE-EU2-${upper(var.environment)}-NLB-INTERNAL"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.private_app_subnet_ids

  tags = {
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "LOADBALANCER"
  }
}

resource "aws_lb" "private_db" {
  name               = "SCALE-EU2-${upper(var.environment)}-NLB-INTERNAL-DB"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.private_db_subnet_ids

  tags = {
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "LOADBALANCER"
  }
}

resource "aws_lb" "public" {
  name               = "SCALE-EU2-${upper(var.environment)}-NLB-EXTERNAL"
  internal           = false
  load_balancer_type = "network"
  depends_on         = [aws_internet_gateway.scale]

  dynamic "subnet_mapping" {
    for_each = var.public_web_subnet_ids

    content {
      subnet_id     = subnet_mapping.value
      allocation_id = var.public_nlb_eip_ids[subnet_mapping.key] # key=index
    }
  }

  tags = {
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "LOADBALANCER"
  }
}

resource "aws_lb" "public_alb" {
  name               = "SCALE-EU2-${upper(var.environment)}-ALB-EXTERNAL"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_web_subnet_ids
  security_groups    = [aws_security_group.public_alb.id]
  depends_on         = [aws_internet_gateway.scale]

  tags = {
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "LOADBALANCER"
  }
}

resource "aws_security_group" "public_alb" {
  name                   = "allow_alb_external_cloudfront_only"
  description            = "Allow ingress from Cloudfront only via update sg lambda"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  lifecycle {
    create_before_destroy = true
  }

  /*
  * 52.56.127.0/25
  * 3.10.17.128/25
  * 3.11.53.0/24
  */
  ingress {
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # cidr_blocks = ["52.56.127.0/25", "3.10.17.128/25", "3.11.53.0/24", "18.200.212.0/23", "52.212.248.0/26", "52.47.139.0/24", "15.188.184.0/24"]
    from_port = 80
    to_port   = 80
  }

  ingress {
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # cidr_blocks = ["52.56.127.0/25", "3.10.17.128/25", "3.11.53.0/24", "18.200.212.0/23", "52.212.248.0/26", "52.47.139.0/24", "15.188.184.0/24"]
    from_port = 443
    to_port   = 443
  }

  egress {
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
  }

  tags = {
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "ECS"
  }
}

resource "aws_api_gateway_vpc_link" "link" {
  name = "SCALE:EU2:ENV:VPC:Link"
  target_arns = [
    aws_lb.private.arn
  ]

  tags = {
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "NETWORK"
  }
}
