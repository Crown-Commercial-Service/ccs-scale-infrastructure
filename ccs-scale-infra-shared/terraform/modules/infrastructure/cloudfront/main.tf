#########################################################
# CloudFront
#
# Distribution for FaT Buyer UI
#########################################################
module "globals" {
  source = "../../globals"
}

resource "aws_s3_bucket" "logs" {
  bucket = "scale-${lower(var.environment)}-s3-cloudfront-logs"
  acl    = "private"

  tags = {
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "S3"
  }
}

resource "aws_cloudfront_distribution" "fat_buyer_ui_distribution" {
  origin {
    domain_name = var.lb_public_dns
    origin_id   = var.lb_public_dns
    
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
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
    target_origin_id = var.lb_public_dns

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "allow-all"
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
    cloudfront_default_certificate = true
  }
}
