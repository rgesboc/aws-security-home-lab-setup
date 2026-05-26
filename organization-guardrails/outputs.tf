output "deny_unapproved_regions_policy_id" {
  description = "SCP ID for the deny-unapproved-regions guardrail."
  value       = aws_organizations_policy.deny_unapproved_regions.id
}

output "allowed_regions" {
  description = "Regions allowed by the SCP."
  value       = sort(tolist(var.allowed_regions))
}

output "attached_target_ids" {
  description = "Organization root, OU, or account IDs where the SCP is attached."
  value       = sort(tolist(var.target_ids))
}
