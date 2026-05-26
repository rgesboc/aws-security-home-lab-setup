Security Baseline
=================

This directory contains a low-cost AWS account security baseline for a personal
lab or workload account.

It intentionally avoids heavier services such as Control Tower, AWS Config,
Security Hub, GuardDuty, Inspector, and Macie. Add those later only when you are
ready to pay for and tune them.

Resources
---------

Managed by default:

- IAM account password policy for any remaining IAM users
- Account-level S3 Block Public Access
- EBS encryption by default in the configured region
- IAM Access Analyzer external access analyzer in the configured region
- Root user usage alerts through EventBridge and SNS

Cost Notes
----------

These settings are chosen to stay light:

- S3 Block Public Access is a control setting, not a workload.
- EBS encryption by default is a regional setting.
- IAM password policy is an account setting.
- IAM Access Analyzer external access analysis is provided at no additional
  charge, while internal and unused access analyzers are paid features.
- Root usage alerts use EventBridge and SNS. SNS email notifications should be
  tiny-cost for a home lab.

Root Usage Alerts
-----------------

By default, this baseline creates root API activity alerts in `aws_region` and
root console sign-in alerts in `us-east-1`.

The `us-east-1` rule exists because AWS records root `ConsoleLogin` events
there. Treat this as a security event listener, not a workload deployment
region. If you want to avoid creating even that listener, set
`enable_root_console_login_notifications = false`.

If you actively use more than one allowed Region, apply this baseline in each
allowed Region or add another regional provider/rule for root API activity.

To receive email alerts, pass both values locally:

```sh
terraform apply \
  -var='enable_root_alert_email_subscription=true' \
  -var='root_alert_email=you@example.com'
```

Confirm the SNS email subscription after Terraform applies.

Deploy
------

Use your IAM Identity Center developer/admin profile for the target account:

```sh
export AWS_PROFILE=robdev
cd account-baseline
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

If you use more than one region, run this baseline once per region where you
want regional settings such as EBS encryption and Access Analyzer.
