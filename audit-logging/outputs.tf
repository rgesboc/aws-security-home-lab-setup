output "cloudtrail_name" {
  description = "Organization CloudTrail trail name."
  value       = aws_cloudtrail.organization_management_events.name
}

output "cloudtrail_bucket_name" {
  description = "S3 bucket receiving organization CloudTrail logs."
  value       = aws_s3_bucket.cloudtrail_log_bucket.id
}

output "cloudtrail_tamper_alert_topic_arn" {
  description = "SNS topic ARN for CloudTrail tamper alerts, if enabled."
  value       = try(aws_sns_topic.cloudtrail_tamper_alert_topic[0].arn, null)
}

output "log_retention_days" {
  description = "Configured CloudTrail log retention in days."
  value       = var.log_retention_days
}
