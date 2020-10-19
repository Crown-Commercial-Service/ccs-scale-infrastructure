#########################################################
# CloudFront Lambda@edge function resources
#
# 1) Add Security Headers
#########################################################

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
  function_name    = "security-headers"
  role             = aws_iam_role.lambda_edge_exec.arn
  description      = "Add HTTP security headers to responses"
  handler          = "index.handler"
  runtime          = "nodejs12.x"
  timeout          = 10
  publish          = true
}
