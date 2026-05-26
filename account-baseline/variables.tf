variable "aws_region" {
  description = "Primary region where regional account security resources are configured."
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Name used for tagging security baseline resources."
  type        = string
  default     = "aws-home-lab-account-baseline"
}

variable "environment" {
  description = "Environment label for tags."
  type        = string
  default     = "home-lab"
}

variable "manage_iam_password_policy" {
  description = "Whether Terraform should manage the IAM account password policy for any remaining IAM users."
  type        = bool
  default     = true
}

variable "enable_s3_account_public_access_block" {
  description = "Whether to block public S3 access at the account level."
  type        = bool
  default     = true
}

variable "enable_ebs_encryption_by_default" {
  description = "Whether to enable EBS encryption by default in aws_region."
  type        = bool
  default     = true
}

variable "enable_external_access_analyzer" {
  description = "Whether to enable IAM Access Analyzer external access findings in aws_region."
  type        = bool
  default     = true
}

variable "enable_root_usage_notifications" {
  description = "Whether to create SNS/EventBridge notifications for root account usage."
  type        = bool
  default     = true
}

variable "enable_root_console_login_notifications" {
  description = "Whether to create the us-east-1 root console login notification rule."
  type        = bool
  default     = true
}

variable "enable_root_alert_email_subscription" {
  description = "Whether to subscribe root_alert_email to the root usage alert topic."
  type        = bool
  default     = false
}

variable "root_alert_email" {
  description = "Optional email address for root usage alerts. Keep private values out of committed tfvars."
  type        = string
  default     = null
  sensitive   = true
}
