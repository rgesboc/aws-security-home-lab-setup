data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  account_id                = data.aws_caller_identity.current.account_id
  cloudtrail_bucket_name    = coalesce(var.cloudtrail_bucket_name, "${var.project_name}-${local.account_id}-${var.aws_region}")
  cloudtrail_name           = "${var.project_name}-organization-trail"
  cloudtrail_arn            = "arn:${data.aws_partition.current.partition}:cloudtrail:${var.aws_region}:${local.account_id}:trail/${local.cloudtrail_name}"
  cloudtrail_tamper_topic   = "${var.project_name}-cloudtrail-tamper-alerts"
  cloudtrail_tamper_rule    = "${var.project_name}-cloudtrail-tamper"
  cloudtrail_log_prefix_arn = "arn:${data.aws_partition.current.partition}:s3:::${local.cloudtrail_bucket_name}/${var.cloudtrail_s3_key_prefix}/AWSLogs"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = local.cloudtrail_bucket_name
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    id     = "expire-cloudtrail-logs"
    status = "Enabled"

    filter {
      prefix = "${var.cloudtrail_s3_key_prefix}/"
    }

    expiration {
      days = var.log_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.log_retention_days
    }
  }
}

data "aws_iam_policy_document" "cloudtrail_logs" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.cloudtrail_logs.arn,
      "${aws_s3_bucket.cloudtrail_logs.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "AllowCloudTrailBucketAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail_logs.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.cloudtrail_arn]
    }
  }

  statement {
    sid    = "AllowCloudTrailLogWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["s3:PutObject"]
    resources = [
      "${local.cloudtrail_log_prefix_arn}/${local.account_id}/*",
      "${local.cloudtrail_log_prefix_arn}/o-*/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.cloudtrail_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  policy = data.aws_iam_policy_document.cloudtrail_logs.json

  depends_on = [
    aws_s3_bucket_public_access_block.cloudtrail_logs,
    aws_s3_bucket_ownership_controls.cloudtrail_logs
  ]
}

resource "aws_cloudtrail" "organization" {
  name                          = local.cloudtrail_name
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  s3_key_prefix                 = var.cloudtrail_s3_key_prefix
  include_global_service_events = true
  is_multi_region_trail         = true
  is_organization_trail         = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_logs
  ]
}

resource "aws_sns_topic" "cloudtrail_tamper_alerts" {
  count = var.enable_cloudtrail_tamper_notifications ? 1 : 0

  name              = local.cloudtrail_tamper_topic
  kms_master_key_id = "alias/aws/sns"
}

resource "aws_sns_topic_policy" "cloudtrail_tamper_alerts" {
  count = var.enable_cloudtrail_tamper_notifications ? 1 : 0

  arn = aws_sns_topic.cloudtrail_tamper_alerts[0].arn

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
        Resource = aws_sns_topic.cloudtrail_tamper_alerts[0].arn
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "cloudtrail_tamper_email" {
  count = var.enable_cloudtrail_tamper_notifications && var.enable_tamper_alert_email_subscription ? 1 : 0

  topic_arn = aws_sns_topic.cloudtrail_tamper_alerts[0].arn
  protocol  = "email"
  endpoint  = var.tamper_alert_email
}

resource "aws_cloudwatch_event_rule" "cloudtrail_tamper" {
  count = var.enable_cloudtrail_tamper_notifications ? 1 : 0

  name        = local.cloudtrail_tamper_rule
  description = "Alert on CloudTrail configuration tampering."

  event_pattern = jsonencode({
    source      = ["aws.cloudtrail"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["cloudtrail.amazonaws.com"]
      eventName = [
        "DeleteTrail",
        "PutEventSelectors",
        "PutInsightSelectors",
        "StopLogging",
        "UpdateTrail"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "cloudtrail_tamper" {
  count = var.enable_cloudtrail_tamper_notifications ? 1 : 0

  rule = aws_cloudwatch_event_rule.cloudtrail_tamper[0].name
  arn  = aws_sns_topic.cloudtrail_tamper_alerts[0].arn
}
