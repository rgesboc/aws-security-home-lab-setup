variable "aws_region" {
  description = "Region used for Organizations API calls."
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Name used for tagging organization guardrail resources."
  type        = string
  default     = "aws-home-lab-organization-guardrails"
}

variable "environment" {
  description = "Environment label for tags."
  type        = string
  default     = "home-lab"
}


variable "trusted_service_access_principals" {
  description = "AWS service principals allowed to integrate with AWS Organizations. Include existing trusted services so Terraform does not disable them."
  type        = set(string)
  default = [
    "cloudtrail.amazonaws.com",
    "sso.amazonaws.com"
  ]
}
variable "target_ids" {
  description = "Organization root, OU, or account IDs to attach the region restriction SCP to. Do not attach until you have reviewed the plan."
  type        = set(string)
  default     = []
}

variable "allowed_regions" {
  description = "Regions where regional AWS actions are allowed."
  type        = set(string)
  default = [
    "us-east-2",
    "us-west-2"
  ]
}

variable "global_service_exemptions" {
  description = "Global or account-management services exempted from the region deny guardrail."
  type        = set(string)
  default = [
    "account:*",
    "aws-portal:*",
    "billing:*",
    "budgets:*",
    "ce:*",
    "cloudfront:*",
    "cur:*",
    "globalaccelerator:*",
    "health:*",
    "iam:*",
    "identitystore:*",
    "organizations:*",
    "route53:*",
    "route53domains:*",
    "sso:*",
    "sts:*",
    "support:*",
    "tax:*"
  ]
}
