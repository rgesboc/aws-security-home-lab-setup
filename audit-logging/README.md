Audit Logging
=============

This directory creates organization audit logging from the management account.

Resources
---------

- Multi-Region organization CloudTrail for management events
- Central S3 bucket for CloudTrail logs
- S3 Block Public Access
- S3 bucket owner enforced object ownership
- S3 versioning
- S3 default encryption with SSE-S3
- Lifecycle expiration for current and noncurrent log objects
- Bucket policy that allows CloudTrail writes and denies insecure transport
- Optional SNS/EventBridge alerts for CloudTrail tampering

Cost Notes
----------

This intentionally logs management events only. Do not enable S3, Lambda, or
other data events until you are ready for the extra event volume and cost.

The first copy of CloudTrail management events delivered to S3 has no CloudTrail
event charge, but S3 storage and request charges still apply. Lifecycle
expiration defaults to 180 days to keep the log archive bounded.

Deploy
------

Run this from the management account:

```sh
export AWS_PROFILE=rob-management
cd audit-logging
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

The default bucket name is based on the current account ID and Region:

```text
aws-home-lab-audit-<account-id>-us-east-2
```

If that name is unavailable, pass an explicit globally unique name:

```sh
terraform apply -var='cloudtrail_bucket_name=my-unique-cloudtrail-log-bucket'
```

To receive CloudTrail tamper alert emails, pass both values locally:

```sh
terraform apply \
  -var='enable_tamper_alert_email_subscription=true' \
  -var='tamper_alert_email=you@example.com'
```

Confirm the SNS email subscription after Terraform applies.
