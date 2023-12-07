#########################################################
# CloudTrail
#
# Cloud Trail and CloudWatch Alarms
#########################################################

locals {
  s3_bucket_name = "scale-${lower(var.environment)}-s3-cloudtrail-logs"
}

module "globals" {
  source = "../globals"
}

##########################
# CloudTrail log bucket
##########################
resource "aws_s3_bucket" "cloudtrail" {
  bucket        = local.s3_bucket_name
  force_destroy = var.cloudwatch_s3_force_destroy

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${local.s3_bucket_name}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${local.s3_bucket_name}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        },
        {
            "Effect": "Deny",
            "Principal": "*",
            "Action": "*",
            "Resource": "arn:aws:s3:::${local.s3_bucket_name}/*",
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
    id      = "expire-after-${var.cloudtrail_s3_log_retention_in_days}-days"
    enabled = true
    expiration {
      days = var.cloudtrail_s3_log_retention_in_days
    }
  }

  tags = {
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "CLOUDTRAIL"
  }
}

##########################
# CloudWatch Log Group
##########################
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/cloudtrail/${lower(var.environment)}"
  retention_in_days = var.cloudtrail_cw_log_retention_in_days

  tags = {
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "CLOUDTRAIL"
  }
}

resource "aws_iam_role" "cloudtrail" {
  name               = "CCS_SCALE_CloudTrail"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
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
    AppType     = "CLOUDTRAIL"
  }
}

resource "aws_iam_policy" "cloudtrail" {
  name        = "CCS_SCALE_CloudTrail"
  path        = "/"
  description = "CCS SCALE cloudtrail policy (provisioned by Terraform)"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:*"
        ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "cloudtrail" {
  role       = aws_iam_role.cloudtrail.name
  policy_arn = aws_iam_policy.cloudtrail.arn
}

##########################
# CloudTrail
##########################
resource "aws_cloudtrail" "scale" {
  name                          = "CCS-EU2-${upper(var.environment)}-CLOUDTRAIL"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail.arn
}

##############################
# SNS Topic: CloudTrail Alarms
##############################
resource "aws_sns_topic" "cloudtrail_alarms" {
  name = "CCS-EU2-${upper(var.environment)}-CLOUDTRAIL-ALARMS"
}

###########################
# Alarm: S3 Bucket Activity
###########################
resource "aws_cloudwatch_log_metric_filter" "s3" {
  name           = "S3BucketActivity"
  pattern        = "{ ($.eventSource = s3.amazonaws.com) && (($.eventName = PutBucketAcl) || ($.eventName = PutBucketPolicy) || ($.eventName = PutBucketCors) || ($.eventName = PutBucketLifecycle) || ($.eventName = PutBucketReplication) || ($.eventName = DeleteBucketPolicy) || ($.eventName = DeleteBucketCors) || ($.eventName = DeleteBucketLifecycle) || ($.eventName = DeleteBucketReplication)) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "S3BucketActivityEventCount"
    namespace = "CloudTrailMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "s3" {
  alarm_name                = "S3BucketActivity"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "S3BucketActivityEventCount"
  namespace                 = "CloudTrailMetrics"
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "This metric monitors S3 bucket activity"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.cloudtrail_alarms.arn]
}

#############################
# Alarm: Network ACL Activity
#############################
resource "aws_cloudwatch_log_metric_filter" "nacl" {
  name           = "NetworkACLEvents"
  pattern        = "{ ($.eventName = CreateNetworkAcl) || ($.eventName = CreateNetworkAclEntry) || ($.eventName = DeleteNetworkAcl) || ($.eventName = DeleteNetworkAclEntry) || ($.eventName = ReplaceNetworkAclEntry) || ($.eventName = ReplaceNetworkAclAssociation) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "NetworkACLEventCount"
    namespace = "CloudTrailMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "nacl" {
  alarm_name                = "NetworkACLChanges"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "NetworkACLEventCount"
  namespace                 = "CloudTrailMetrics"
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "This metric monitors network ACL changes"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.cloudtrail_alarms.arn]
}

################################
# Alarm: Security Group Activity
################################
resource "aws_cloudwatch_log_metric_filter" "security_group" {
  name           = "SecurityGroupEvents"
  pattern        = "{ ($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) || ($.eventName = RevokeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupEgress) || ($.eventName = CreateSecurityGroup) || ($.eventName = DeleteSecurityGroup) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "SecurityGroupEventCount"
    namespace = "CloudTrailMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "security_group" {
  alarm_name                = "SecurityGroupChanges"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "SecurityGroupEventCount"
  namespace                 = "CloudTrailMetrics"
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "This metric monitors Security Group changes"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.cloudtrail_alarms.arn]
}

#################################
# Alarm: Network Gateway Activity
#################################
resource "aws_cloudwatch_log_metric_filter" "network_gateway" {
  name           = "GatewayChanges"
  pattern        = "{ ($.eventName = CreateCustomerGateway) || ($.eventName = DeleteCustomerGateway) || ($.eventName = AttachInternetGateway) || ($.eventName = CreateInternetGateway) || ($.eventName = DeleteInternetGateway) || ($.eventName = DetachInternetGateway) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "GatewayEventCount"
    namespace = "CloudTrailMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "network_gateway" {
  alarm_name                = "NetworkGatewayChanges"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "GatewayEventCount"
  namespace                 = "CloudTrailMetrics"
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "This metric monitors Network Gateway changes"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.cloudtrail_alarms.arn]
}

#####################
# Alarm: VPC Activity
#####################
resource "aws_cloudwatch_log_metric_filter" "vpc" {
  name           = "VpcChanges"
  pattern        = "{ ($.eventName = CreateVpc) || ($.eventName = DeleteVpc) || ($.eventName = ModifyVpcAttribute) || ($.eventName = AcceptVpcPeeringConnection) || ($.eventName = CreateVpcPeeringConnection) || ($.eventName = DeleteVpcPeeringConnection) || ($.eventName = RejectVpcPeeringConnection) || ($.eventName = AttachClassicLinkVpc) || ($.eventName = DetachClassicLinkVpc) || ($.eventName = DisableVpcClassicLink) || ($.eventName = EnableVpcClassicLink) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "VpcEventCount"
    namespace = "CloudTrailMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "vpc" {
  alarm_name                = "VpcChanges"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "VpcEventCount"
  namespace                 = "CloudTrailMetrics"
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "This metric monitors VPC changes"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.cloudtrail_alarms.arn]
}

#####################
# Alarm: EC2 Instance
#####################
resource "aws_cloudwatch_log_metric_filter" "ec2" {
  name           = "EC2InstanceChanges"
  pattern        = "{ ($.eventName = RunInstances) || ($.eventName = RebootInstances) || ($.eventName = StartInstances) || ($.eventName = StopInstances) || ($.eventName = TerminateInstances) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "EC2InstanceEventCount"
    namespace = "CloudTrailMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2" {
  alarm_name                = "EC2InstanceChanges"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "EC2InstanceEventCount"
  namespace                 = "CloudTrailMetrics"
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "This metric monitors EC2 Instance changes"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.cloudtrail_alarms.arn]
}

###########################
# Alarm: EC2 Large Instance
###########################
resource "aws_cloudwatch_log_metric_filter" "ec2_large" {
  name           = "EC2LargeInstanceChanges"
  pattern        = "{ ($.eventName = RunInstances) && (($.requestParameters.instanceType = *.8xlarge) || ($.requestParameters.instanceType = *.4xlarge)) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "EC2LargeInstanceEventCount"
    namespace = "CloudTrailMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_large" {
  alarm_name                = "EC2LargeInstanceChanges"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "EC2LargeInstanceEventCount"
  namespace                 = "CloudTrailMetrics"
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "This metric monitors EC2 Large Instance changes"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.cloudtrail_alarms.arn]
}

############################
# Alarm: CloudTrail Activity
############################
resource "aws_cloudwatch_log_metric_filter" "cloudtrail" {
  name           = "CloudTrailChanges"
  pattern        = "{ ($.eventName = CreateTrail) || ($.eventName = UpdateTrail) || ($.eventName = DeleteTrail) || ($.eventName = StartLogging) || ($.eventName = StopLogging) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "CloudTrailEventCount"
    namespace = "CloudTrailMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudtrail" {
  alarm_name                = "CloudTrailChanges"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "CloudTrailEventCount"
  namespace                 = "CloudTrailMetrics"
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "This metric monitors Cloud Trail changes"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.cloudtrail_alarms.arn]
}

############################
# Alarm: Console Activity
############################
resource "aws_cloudwatch_log_metric_filter" "console_sign_in" {
  name           = "ConsoleSignInFailures"
  pattern        = "{ ($.eventName = ConsoleLogin) && ($.errorMessage = \"Failed authentication\") }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "ConsoleSigninFailureCount"
    namespace = "CloudTrailMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "console_sign_in" {
  alarm_name                = "ConsoleSignInFailures"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "ConsoleSigninFailureCount"
  namespace                 = "CloudTrailMetrics"
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "This metric monitors Console Sign In failures"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.cloudtrail_alarms.arn]
}

###############################
# Alarm: Authorization Activity
###############################
resource "aws_cloudwatch_log_metric_filter" "authorization" {
  name           = "AuthorizationFailures"
  pattern        = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "AuthorizationFailureCount"
    namespace = "CloudTrailMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "authorization" {
  alarm_name                = "AuthorizationFailures"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "AuthorizationFailureCount"
  namespace                 = "CloudTrailMetrics"
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "This metric monitors Authorization failures"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.cloudtrail_alarms.arn]
}

###############################
# Alarm: IAM Policy Activity
###############################
resource "aws_cloudwatch_log_metric_filter" "iam_policy" {
  name           = "IAMPolicyChanges"
  pattern        = "{($.eventName=DeleteGroupPolicy)||($.eventName=DeleteRolePolicy)||($.eventName=DeleteUserPolicy)||($.eventName=PutGroupPolicy)||($.eventName=PutRolePolicy)||($.eventName=PutUserPolicy)||($.eventName=CreatePolicy)||($.eventName=DeletePolicy)||($.eventName=CreatePolicyVersion)||($.eventName=DeletePolicyVersion)||($.eventName=AttachRolePolicy)||($.eventName=DetachRolePolicy)||($.eventName=AttachUserPolicy)||($.eventName=DetachUserPolicy)||($.eventName=AttachGroupPolicy)||($.eventName=DetachGroupPolicy)}"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name

  metric_transformation {
    name      = "IAMPolicyEventCount"
    namespace = "CloudTrailMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "iam_policy" {
  alarm_name                = "IAMPolicyChanges"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "IAMPolicyEventCount"
  namespace                 = "CloudTrailMetrics"
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "This metric monitors IAM Policy changes"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.cloudtrail_alarms.arn]
}
