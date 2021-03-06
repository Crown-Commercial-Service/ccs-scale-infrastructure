#########################################################
# CloudFront
#
# Distribution for FaT Buyer UI
#########################################################
module "globals" {
  source = "../../globals"
}

# Aliased provider for us-east-1 region for use by specific resources (e.g. ACM certificates)
provider "aws" {
  alias  = "nvirginia"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.aws_account_id}:role/CCS_SCALE_Build"
  }
}

resource "random_password" "cloudfront_id" {
  length  = 16
  special = false
  # override_special = "_%@"
}

resource "aws_s3_bucket" "logs" {
  bucket        = "scale-${lower(var.environment)}-s3-cloudfront-logs"
  acl           = "private"
  force_destroy = var.force_destroy_cloudfront_logs_bucket

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Deny",
            "Principal": "*",
            "Action": "*",
            "Resource": "arn:aws:s3:::scale-${lower(var.environment)}-s3-cloudfront-logs/*",
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}
POLICY

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "expire-after-${var.cloudfront_s3_log_retention_in_days}-days"
    enabled = true
    expiration {
      days = var.cloudfront_s3_log_retention_in_days
    }
  }

  tags = {
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "S3"
  }
}

# CDN+ALB custom domain names
data "aws_ssm_parameter" "hosted_zone_name_cdn" {
  name = "${lower(var.environment)}-hosted-zone-name-cdn"
}

data "aws_ssm_parameter" "hosted_zone_name_alb" {
  name = "${lower(var.environment)}-hosted-zone-name-alb"
}

# CDN ACM SSL certificate
data "aws_acm_certificate" "cdn" {
  domain   = data.aws_ssm_parameter.hosted_zone_name_cdn.value
  statuses = ["ISSUED"]
  provider = aws.nvirginia
}

##############################################################
# Lambda@Edge functions
##############################################################
module "functions" {
  source         = "./functions"
  aws_account_id = var.aws_account_id
}

##############################################################
# Cloudfront distribution
##############################################################
resource "aws_cloudfront_distribution" "fat_buyer_ui_distribution" {
  origin {
    domain_name = data.aws_ssm_parameter.hosted_zone_name_alb.value
    origin_id   = data.aws_ssm_parameter.hosted_zone_name_alb.value

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "CloudFrontID"
      value = random_password.cloudfront_id.result
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "FaT Buyer UI"

  web_acl_id = aws_waf_web_acl.buyer_ui.id

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.logs.bucket_domain_name
    prefix          = "fat-buyer-ui"
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = data.aws_ssm_parameter.hosted_zone_name_alb.value

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }

    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = module.functions.add_security_headers_function_qarn
      include_body = false
    }

    viewer_protocol_policy = "https-only"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "CLOUDFRONT"
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = data.aws_acm_certificate.cdn.arn
    minimum_protocol_version       = "TLSv1.2_2019"
    ssl_support_method             = "sni-only"
  }

  aliases = [data.aws_ssm_parameter.hosted_zone_name_cdn.value]
}

##############################################################
# Route53 CDN Alias ('A') record
##############################################################
data "aws_route53_zone" "cdn" {
  name         = data.aws_ssm_parameter.hosted_zone_name_cdn.value
  private_zone = false
}

resource "aws_route53_record" "cdn_alias" {
  zone_id = data.aws_route53_zone.cdn.zone_id
  name    = data.aws_ssm_parameter.hosted_zone_name_cdn.value
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.fat_buyer_ui_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.fat_buyer_ui_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}
