locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_account_password_policy" "iam_user_password_policy" {
  count = var.manage_iam_password_policy ? 1 : 0

  minimum_password_length        = 16
  require_lowercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  require_uppercase_characters   = true
  allow_users_to_change_password = true
  max_password_age               = 90
  password_reuse_prevention      = 24
}

resource "aws_s3_account_public_access_block" "account_public_access_block" {
  count = var.enable_s3_account_public_access_block ? 1 : 0

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_ebs_encryption_by_default" "regional_default_encryption" {
  count = var.enable_ebs_encryption_by_default ? 1 : 0

  enabled = true
}

resource "aws_accessanalyzer_analyzer" "external_access" {
  count = var.enable_external_access_analyzer ? 1 : 0

  analyzer_name = "external-access"
  type          = "ACCOUNT"
}

resource "aws_sns_topic" "root_usage_alert_topic" {
  count = var.enable_root_usage_notifications ? 1 : 0

  provider = aws.us_east_1

  name              = "root-usage-alerts"
  kms_master_key_id = "alias/aws/sns"
}

resource "aws_sns_topic_policy" "root_usage_alert_topic_policy" {
  count = var.enable_root_usage_notifications ? 1 : 0

  provider = aws.us_east_1

  arn = aws_sns_topic.root_usage_alert_topic[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgePublish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.root_usage_alert_topic[0].arn
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "root_usage_email_subscription" {
  count = var.enable_root_usage_notifications && var.enable_root_alert_email_subscription ? 1 : 0

  provider = aws.us_east_1

  topic_arn = aws_sns_topic.root_usage_alert_topic[0].arn
  protocol  = "email"
  endpoint  = var.root_alert_email
}

resource "aws_cloudwatch_event_rule" "root_console_login_rule" {
  count = var.enable_root_usage_notifications && var.enable_root_console_login_notifications ? 1 : 0

  provider = aws.us_east_1

  name        = "root-console-login"
  description = "Alert when the AWS account root user signs in to the console."

  event_pattern = jsonencode({
    source      = ["aws.signin"]
    detail-type = ["AWS Console Sign In via CloudTrail"]
    detail = {
      eventName = ["ConsoleLogin"]
      userIdentity = {
        type = ["Root"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "root_console_login_target" {
  count = var.enable_root_usage_notifications && var.enable_root_console_login_notifications ? 1 : 0

  provider = aws.us_east_1

  rule = aws_cloudwatch_event_rule.root_console_login_rule[0].name
  arn  = aws_sns_topic.root_usage_alert_topic[0].arn
}

resource "aws_cloudwatch_event_rule" "root_api_activity_rule" {
  count = var.enable_root_usage_notifications ? 1 : 0

  name        = "root-api-activity"
  description = "Alert when the AWS account root user makes API calls in this region."

  event_pattern = jsonencode({
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      userIdentity = {
        type = ["Root"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "root_api_activity_target" {
  count = var.enable_root_usage_notifications ? 1 : 0

  rule = aws_cloudwatch_event_rule.root_api_activity_rule[0].name
  arn  = aws_sns_topic.root_usage_alert_topic[0].arn
}
