variable "aws_region" {
  description = "Region where the organization CloudTrail trail, SNS topic, and EventBridge alerts are created."
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Name used for audit logging resources."
  type        = string
  default     = "aws-home-lab-audit"
}

variable "environment" {
  description = "Environment label for tags."
  type        = string
  default     = "home-lab"
}

variable "cloudtrail_bucket_name" {
  description = "Optional explicit S3 bucket name for CloudTrail logs. Must be globally unique."
  type        = string
  default     = null
}

variable "cloudtrail_s3_key_prefix" {
  description = "S3 key prefix for CloudTrail logs."
  type        = string
  default     = "cloudtrail"
}

variable "log_retention_days" {
  description = "Number of days to retain CloudTrail log objects before expiration."
  type        = number
  default     = 180
}

variable "enable_cloudtrail_tamper_notifications" {
  description = "Whether to create SNS/EventBridge alerts for CloudTrail tampering actions."
  type        = bool
  default     = true
}

variable "enable_tamper_alert_email_subscription" {
  description = "Whether to subscribe tamper_alert_email to the CloudTrail tamper alert topic."
  type        = bool
  default     = false
}

variable "tamper_alert_email" {
  description = "Optional email address for CloudTrail tamper alerts. Keep private values out of committed tfvars."
  type        = string
  default     = null
  sensitive   = true
}
