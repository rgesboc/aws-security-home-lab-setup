Organization Guardrails
=======================

This directory contains AWS Organizations guardrails for the management account.

Region Restriction
------------------

AWS default Regions cannot be disabled. Opt-in Regions can be enabled or
disabled, but default Regions remain enabled. To keep workloads in approved
Regions, use an SCP that denies regional service actions outside the allowed
Region list.

This baseline allows:

- `us-east-2`
- `us-west-2`

It exempts global and account-management services such as IAM, Organizations,
IAM Identity Center, Route 53, CloudFront, billing, budgets, and support.


Trusted Service Access
----------------------

This root manages AWS Organizations trusted service access. Keep every existing
trusted service in `trusted_service_access_principals`; otherwise Terraform may
disable services that are omitted.

Enabled by default:

- `cloudtrail.amazonaws.com`
- `sso.amazonaws.com`

`cloudtrail.amazonaws.com` is required for organization CloudTrail.
`sso.amazonaws.com` is required for IAM Identity Center account access.

Deploy
------

Run this from the management account profile:

```sh
export AWS_PROFILE=rob-management
cd organization-guardrails
terraform init
terraform fmt -recursive
terraform validate
terraform plan
```

By default, `target_ids` is empty, so Terraform creates the policy but does not
attach it. After reviewing the policy, pass the workload account ID, OU ID, or
root ID locally:

```sh
terraform plan -var='target_ids=["123456789012"]'
terraform apply -var='target_ids=["123456789012"]'
```

Prefer attaching to a workload OU once your account structure is stable. Avoid
testing region-deny guardrails first on accounts that you cannot easily recover
from.
