locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_organizations_policy" "deny_unapproved_regions" {
  name        = "DenyUnapprovedRegions"
  description = "Deny regional AWS actions outside the approved home lab Regions."
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyActionsOutsideApprovedRegions"
        Effect    = "Deny"
        NotAction = sort(tolist(var.global_service_exemptions))
        Resource  = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = sort(tolist(var.allowed_regions))
          }
        }
      }
    ]
  })
}

resource "aws_organizations_policy_attachment" "deny_unapproved_regions" {
  for_each = var.target_ids

  policy_id = aws_organizations_policy.deny_unapproved_regions.id
  target_id = each.value
}
