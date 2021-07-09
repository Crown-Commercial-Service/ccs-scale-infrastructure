
#########################################################
# KMS
#
# Customer Manager KMS Keys
#########################################################

module "globals" {
  source = "../globals"
}

##########################
# CloudTrail KMS Key
##########################
resource "aws_kms_key" "cloudtrail" {
  description         = "CloudTrail Logs Key"
  enable_key_rotation = true

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
          "AWS": "arn:aws:iam::${var.aws_account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow CloudTrail to encrypt logs",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "kms:GenerateDataKey*",
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "kms:EncryptionContext:aws:cloudtrail:arn": [
            "arn:aws:cloudtrail:*:${var.aws_account_id}:trail/*"
          ]
        }
      }
    },
    {
      "Sid": "Allow CloudWatch permission to use key",
      "Effect": "Allow",
      "Principal": {
          "Service": "logs.eu-west-2.amazonaws.com"
      },
      "Action": [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
      ],
      "Resource": "*",
      "Condition": {
          "ArnEquals": {
              "kms:EncryptionContext:aws:logs:arn": "arn:aws:logs:*:${var.aws_account_id}:*"
          }
      }
    }
  ]
}
EOF

  tags = {
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "KMS"
  }
}

resource "aws_kms_alias" "cloudtrail" {
  name          = "alias/cloudtrail"
  target_key_id = aws_kms_key.cloudtrail.key_id
}


##########################
# CloudWatch KMS Key
# 
# Can be used for CW logs
# across other repos
##########################
resource "aws_kms_key" "cloudwatch" {
  description         = "CloudWatch Logs Key"
  enable_key_rotation = true

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
          "AWS": "arn:aws:iam::${var.aws_account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow CloudWatch permission to use key",
      "Effect": "Allow",
      "Principal": {
          "Service": "logs.eu-west-2.amazonaws.com"
      },
      "Action": [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
      ],
      "Resource": "*",
      "Condition": {
          "ArnEquals": {
              "kms:EncryptionContext:aws:logs:arn": "arn:aws:logs:*:${var.aws_account_id}:*"
          }
      }
    }  
  ]
}
EOF

  tags = {
    Project     = module.globals.project_name
    Environment = upper(var.environment)
    Cost_Code   = module.globals.project_cost_code
    AppType     = "KMS"
  }
}

resource "aws_kms_alias" "cloudwatch" {
  name          = "alias/cloudwatch"
  target_key_id = aws_kms_key.cloudwatch.key_id
}
