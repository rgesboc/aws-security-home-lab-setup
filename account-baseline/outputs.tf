output "s3_account_public_access_block_enabled" {
  description = "Whether account-level S3 Block Public Access is managed by this baseline."
  value       = var.enable_s3_account_public_access_block
}

output "ebs_encryption_by_default_enabled" {
  description = "Whether EBS encryption by default is managed in aws_region."
  value       = var.enable_ebs_encryption_by_default
}

output "external_access_analyzer_name" {
  description = "IAM Access Analyzer external access analyzer name, if enabled."
  value       = try(aws_accessanalyzer_analyzer.external[0].analyzer_name, null)
}

output "root_usage_alert_topic_arn" {
  description = "SNS topic ARN for root usage alerts, if enabled."
  value       = try(aws_sns_topic.root_usage_alerts[0].arn, null)
}
