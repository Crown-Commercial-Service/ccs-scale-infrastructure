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

  subnet_mapping {
    # TODO: Iterate on subnet IDs (must be hardcoded values)
    subnet_id     = var.public_web_subnet_ids[0]
    allocation_id = var.eip_id_nlb
  }

  tags = {
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "LOADBALANCER"
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
