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
  security_groups    = [aws_security_group.public_alb_cf_global.id, aws_security_group.public_alb_cf_regional.id]
  depends_on         = [aws_internet_gateway.scale]

  tags = {
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "LOADBALANCER"
  }
}

resource "aws_security_group" "public_alb_cf_global" {
  name                   = "allow_alb_external_cloudfront_only"
  description            = "Allow ingress from Cloudfront only via update sg lambda"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  lifecycle {
    create_before_destroy = true
  }

  # TODO: Use the auto update lambda to manage these ingress rules
  ingress {
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # cidr_blocks = ["204.246.164.0/22", "13.35.0.0/16", "204.246.174.0/23", "36.103.232.0/25", "119.147.182.128/26", "118.193.97.128/25", "120.232.236.128/26", "204.246.176.0/20", "65.8.0.0/16", "65.9.0.0/17", "120.253.241.160/27", "13.124.199.0/24", "35.167.191.128/26", "18.200.212.0/23", "99.79.169.0/24", "52.15.127.128/26", "34.223.12.224/27", "54.233.255.128/26", "13.54.63.128/26", "13.59.250.0/26", "3.234.232.224/27", "52.66.194.128/26", "13.228.69.0/24", "64.252.64.0/18", "18.216.170.128/25", "3.231.2.0/25", "52.220.191.0/26", "34.232.163.208/29", "35.162.63.192/26", "34.223.80.192/26", "34.226.14.0/24", "13.113.203.0/24", "34.195.252.0/24", "52.52.191.128/26", "52.56.127.0/25", "34.216.51.0/25", "52.199.127.192/26", "52.212.248.0/26", "13.210.67.128/26", "35.158.136.0/24", "52.57.254.0/24", "52.78.247.128/26", "52.47.139.0/24", "13.113.196.64/26", "13.233.177.192/26", "13.48.32.0/24", "15.188.184.0/24", "15.207.13.128/25", "18.229.220.192/26", "3.10.17.128/25", "3.11.53.0/24", "3.128.93.0/24", "3.134.215.0/24", "3.236.169.192/26", "3.236.48.0/23", "44.227.178.0/24", "44.234.108.128/25", "44.234.90.252/30"]
    from_port = 80
    to_port   = 80
  }

  ingress {
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    to_port     = 443
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

    # Tags required by auto-update
    Name       = "cloudfront_g"
    AutoUpdate = true
    Protocol   = "http"
  }
}

resource "aws_security_group" "public_alb_cf_regional" {
  name                   = "allow_alb_external_cloudfront_only_regional"
  description            = "Allow ingress from Cloudfront only via update sg lambda"
  vpc_id                 = var.vpc_id
  revoke_rules_on_delete = true

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # cidr_blocks = ["204.246.164.0/22", "13.35.0.0/16", "204.246.174.0/23", "36.103.232.0/25", "119.147.182.128/26", "118.193.97.128/25", "120.232.236.128/26", "204.246.176.0/20", "65.8.0.0/16", "65.9.0.0/17", "120.253.241.160/27", "13.124.199.0/24", "35.167.191.128/26", "18.200.212.0/23", "99.79.169.0/24", "52.15.127.128/26", "34.223.12.224/27", "54.233.255.128/26", "13.54.63.128/26", "13.59.250.0/26", "3.234.232.224/27", "52.66.194.128/26", "13.228.69.0/24", "64.252.64.0/18", "18.216.170.128/25", "3.231.2.0/25", "52.220.191.0/26", "34.232.163.208/29", "35.162.63.192/26", "34.223.80.192/26", "34.226.14.0/24", "13.113.203.0/24", "34.195.252.0/24", "52.52.191.128/26", "52.56.127.0/25", "34.216.51.0/25", "52.199.127.192/26", "52.212.248.0/26", "13.210.67.128/26", "35.158.136.0/24", "52.57.254.0/24", "52.78.247.128/26", "52.47.139.0/24", "13.113.196.64/26", "13.233.177.192/26", "13.48.32.0/24", "15.188.184.0/24", "15.207.13.128/25", "18.229.220.192/26", "3.10.17.128/25", "3.11.53.0/24", "3.128.93.0/24", "3.134.215.0/24", "3.236.169.192/26", "3.236.48.0/23", "44.227.178.0/24", "44.234.108.128/25", "44.234.90.252/30"]
    from_port = 80
    to_port   = 80
  }

  ingress {
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    to_port     = 443
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

    # Tags required by auto-update
    Name       = "cloudfront_r"
    AutoUpdate = true
    Protocol   = "http"
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

resource "aws_lb_listener" "port_80" {
  load_balancer_arn = aws_lb.public_alb.arn
  port              = "80"
  protocol          = "HTTP"
  # ssl_policy        = "ELBSecurityPolicy-2016-08"
  # certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = "<html><body>Unauthorised</body></html>"
      status_code  = "403"
    }
  }
}
