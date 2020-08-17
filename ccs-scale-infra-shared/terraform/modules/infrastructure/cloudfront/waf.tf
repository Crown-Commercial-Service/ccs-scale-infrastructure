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

resource "aws_waf_web_acl" "buyer_ui" {
  name        = "SCALE-EU2-${upper(var.environment)}-EXT-FatBuyerUI"
  metric_name = "wafBuyerUi"

  depends_on = [
    aws_waf_rate_based_rule.rate_limiting_rule,
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
}
