#########################################################
# Web Application Firewall
#
# Placeholder - rules TBD
#########################################################
resource "aws_waf_rate_based_rule" "rate_limiting_rule" {
  name        = "rateLimitWAFRule"
  metric_name = "rateLimitWAFRule"

  rate_key   = "IP"
  rate_limit = 1000
}

#########################################################
# XSS protection
#########################################################
resource "aws_waf_xss_match_set" "xss" {
  name = "xss_match_set"

  xss_match_tuples {
    text_transformation = "URL_DECODE"

    field_to_match {
      type = "URI"
    }
  }

  xss_match_tuples {
    text_transformation = "URL_DECODE"

    field_to_match {
      type = "QUERY_STRING"
    }
  }

  xss_match_tuples {
    text_transformation = "HTML_ENTITY_DECODE"

    field_to_match {
      type = "BODY"
    }
  }
}


resource "aws_waf_rule" "xss" {
  depends_on  = [aws_waf_xss_match_set.xss]
  name        = "xssWAFRule"
  metric_name = "xssWAFRule"

  predicates {
    data_id = aws_waf_xss_match_set.xss.id
    negated = false
    type    = "XssMatch"
  }
}

resource "aws_waf_web_acl" "buyer_ui" {
  name        = "SCALE-EU2-${upper(var.environment)}-EXT-${upper(var.resource_label)}"
  metric_name = "waf${replace(var.resource_label, "-", "")}"

  depends_on = [
    aws_waf_rate_based_rule.rate_limiting_rule,
    aws_waf_rule.xss
  ]

  default_action {
    type = "ALLOW"
  }

  rules {
    action {
      type = "BLOCK"
    }

    priority = 1
    rule_id  = aws_waf_rate_based_rule.rate_limiting_rule.id
    type     = "RATE_BASED"
  }

  rules {
    action {
      type = "BLOCK"
    }

    priority = 2
    rule_id  = aws_waf_rule.xss.id
    type     = "REGULAR"
  }
}
