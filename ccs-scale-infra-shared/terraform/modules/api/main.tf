#########################################################
# Infrastructure: API
#
# Deploy API Gateway account level resources. 
# API Deployments are done later, after services.
#########################################################

provider "aws" {
  profile = "default"
  region  = "eu-west-2"

  assume_role {
    role_arn = "arn:aws:iam::${var.aws_account_id}:role/CCS_SCALE_Build"
  }
}

module "globals" {
  source = "../globals"
}

# API Gateway account level settings
resource "aws_api_gateway_account" "scale" {
  cloudwatch_role_arn = aws_iam_role.api_gw_cloudwatch_logs_role.arn
}

resource "aws_iam_role" "api_gw_cloudwatch_logs_role" {
  name = "SCALE_ApiGateway_PushToCWLog"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = {
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "APIGATEWAY"
  }
}

resource "aws_iam_role_policy" "cloudwatch" {
  name   = "default"
  role   = aws_iam_role.api_gw_cloudwatch_logs_role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

# API gateway, top-level..
resource "aws_api_gateway_rest_api" "scale" {
  name        = "SCALE:EU2:${upper(var.environment)}:API"
  description = "API Gateway"

  tags = {
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "APIGATEWAY"
  }
}

# TODO - maybe remove this
# Base path resources (/scale/)
resource "aws_api_gateway_resource" "scale" {
  rest_api_id = aws_api_gateway_rest_api.scale.id
  parent_id   = aws_api_gateway_rest_api.scale.root_resource_id
  path_part   = "scale"
}

resource "aws_cloudwatch_log_group" "api_gw_execution" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.scale.id}/${lower(var.environment)}"
  retention_in_days = 7
}
