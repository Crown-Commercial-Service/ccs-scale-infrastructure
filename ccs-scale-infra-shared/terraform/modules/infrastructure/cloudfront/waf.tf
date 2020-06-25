#########################################################
# Web Application Firewall
#
# Placeholder - rules TBD
#########################################################
resource "aws_waf_web_acl" "buyer_ui" {
  name        = "SCALE-EU2-${upper(var.environment)}-EXT-FatBuyerUI"
  metric_name = "wafBuyerUi"

  default_action {
    type = "ALLOW"
  }
}
