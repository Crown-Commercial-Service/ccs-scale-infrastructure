#########################################################
# CloudTrail
#
# Cloud Trail and CloudWatch Alarms
#########################################################
provider "aws" {
  profile = "default"
  region  = "eu-west-2"

  assume_role {
    role_arn = "arn:aws:iam::${var.aws_account_id}:role/CCS_SCALE_Build"
  }
}

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
  force_destroy = true

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
        }
    ]
}
POLICY
}

##########################
# CloudWatch Log Group
##########################
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/cloudtrail/${lower(var.environment)}"
  retention_in_days = 30

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
  cloud_watch_logs_group_arn    = aws_cloudwatch_log_group.cloudtrail.arn
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
