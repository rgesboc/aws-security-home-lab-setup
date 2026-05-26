locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_organizations_policy" "region_restriction_scp" {
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

resource "aws_organizations_policy_attachment" "region_restriction_scp_attachment" {
  for_each = var.target_ids

  policy_id = aws_organizations_policy.region_restriction_scp.id
  target_id = each.value
}

resource "aws_organizations_organization" "trusted_service_access" {
  aws_service_access_principals = sort(tolist(var.trusted_service_access_principals))

  feature_set = "ALL"
}