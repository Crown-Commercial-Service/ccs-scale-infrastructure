#########################################################
# CloudFront Lambda@edge function resources
#
# 1) Add Security Headers
#########################################################

locals {
  function_name = "scale-${var.resource_label}-${lower(var.environment)}-security-headers"
}
# Aliased provider for us-east-1 region for use by specific resources (e.g. ACM certificates)
provider "aws" {
  alias  = "lambda_edge"
  region = var.lambda_edge_region
  assume_role {
    role_arn = "arn:aws:iam::${var.aws_account_id}:role/CCS_SCALE_Build"
  }
}

resource "aws_iam_role" "lambda_edge_exec" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

data "aws_iam_policy" "ssm_read_only_access" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_ro_attach" {
  role       = aws_iam_role.lambda_edge_exec.name
  policy_arn = data.aws_iam_policy.ssm_read_only_access.arn
}

data "aws_iam_policy" "lambda_basic_exec" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_exec_attach" {
  role       = aws_iam_role.lambda_edge_exec.name
  policy_arn = data.aws_iam_policy.lambda_basic_exec.arn
}

data "archive_file" "lambda_security_headers_zip" {
  type        = "zip"
  source_dir  = "${path.module}/security-headers"
  output_path = "${path.module}/.build/security-headers.zip"
}

resource "aws_lambda_function" "security_headers" {
  # Provision in Lambda@edge region (us-east-1)
  provider = aws.lambda_edge

  filename         = "${path.module}/.build/security-headers.zip"
  source_code_hash = data.archive_file.lambda_security_headers_zip.output_base64sha256
  function_name    = local.function_name
  role             = aws_iam_role.lambda_edge_exec.arn
  description      = "Add HTTP security headers to responses"
  handler          = "index.handler"
  runtime          = "nodejs12.x"
  timeout          = 10
  publish          = true
}

# Parameter that will be read by security_headers Lambda@edge function
resource "aws_ssm_parameter" "csp" {
  name      = "/bat/${local.function_name}-csp"
  type      = "String"
  value     = var.content_security_policy
  overwrite = true
}
