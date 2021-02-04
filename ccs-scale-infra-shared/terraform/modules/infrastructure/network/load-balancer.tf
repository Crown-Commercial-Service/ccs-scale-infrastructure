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

# Data sources for the external ALB custom domain names and SSL certs

# FaT
data "aws_ssm_parameter" "hosted_zone_name_alb_fat" {
  name = "${lower(var.environment)}-hosted-zone-name-alb"
}

# BaT Client
data "aws_ssm_parameter" "hosted_zone_name_alb_bat_client" {
  name = "/bat/${lower(var.environment)}-hosted-zone-name-alb-bat-client"
}

# BaT Backend (Spree)
data "aws_ssm_parameter" "hosted_zone_name_alb_bat_backend" {
  name = "/bat/${lower(var.environment)}-hosted-zone-name-alb-bat-backend"
}

data "aws_acm_certificate" "alb_fat" {
  domain   = data.aws_ssm_parameter.hosted_zone_name_alb_fat.value
  statuses = ["ISSUED"]
}

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

##############################################################
# Single external ALB listner on port 443
# Services must attach listener rules and certs as required
##############################################################
resource "aws_lb_listener" "external_alb_port_443" {
  load_balancer_arn = aws_lb.public_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = data.aws_acm_certificate.alb_fat.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = "<html><body>Unauthorised</body></html>"
      status_code  = "403"
    }
  }
}

resource "aws_ssm_parameter" "external_alb_port_443_listener_arn" {
  name  = "${lower(var.environment)}-ext-alb-port-443-listener-arn"
  type  = "String"
  value = aws_lb_listener.external_alb_port_443.arn
}

##############################################################
# Route53 CDN Alias ('A') records in external ALB
##############################################################
data "aws_route53_zone" "fat" {
  name         = data.aws_ssm_parameter.hosted_zone_name_alb_fat.value
  private_zone = false
}

data "aws_route53_zone" "bat_client" {
  name         = data.aws_ssm_parameter.hosted_zone_name_alb_bat_client.value
  private_zone = false
}

data "aws_route53_zone" "bat_backend" {
  name         = data.aws_ssm_parameter.hosted_zone_name_alb_bat_backend.value
  private_zone = false
}

resource "aws_route53_record" "alias_fat" {
  zone_id = data.aws_route53_zone.fat.zone_id
  name    = data.aws_ssm_parameter.hosted_zone_name_alb_fat.value
  type    = "A"

  alias {
    name                   = aws_lb.public_alb.dns_name
    zone_id                = aws_lb.public_alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "alias_bat_client" {
  zone_id = data.aws_route53_zone.bat_client.zone_id
  name    = data.aws_ssm_parameter.hosted_zone_name_alb_bat_client.value
  type    = "A"

  alias {
    name                   = aws_lb.public_alb.dns_name
    zone_id                = aws_lb.public_alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "alias_bat_backend" {
  zone_id = data.aws_route53_zone.bat_backend.zone_id
  name    = data.aws_ssm_parameter.hosted_zone_name_alb_bat_backend.value
  type    = "A"

  alias {
    name                   = aws_lb.public_alb.dns_name
    zone_id                = aws_lb.public_alb.zone_id
    evaluate_target_health = true
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
