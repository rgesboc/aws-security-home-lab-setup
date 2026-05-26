AWS Home Lab Security Baseline
==============================

Goal
----
Build a low-cost AWS security home lab with account baselines, organization
guardrails, and audit logging without committing or storing raw secrets in
code, Terraform variables, Terraform state, or GitHub.

Current Repo Scaffold
---------------------
This repo is organized by blast radius:

  - `account-baseline/`: per-account security baseline controls
  - `audit-logging/`: organization CloudTrail and central log bucket
  - `organization-guardrails/`: AWS Organizations SCP guardrails
  - `scripts/`: small local AWS CLI helper scripts

Organization audit logging lives in `audit-logging/`.

Low-Cost Account Security Baseline
----------------------------------
Use `account-baseline/` for account-level controls that are useful in a home
lab and should not create meaningful monthly cost by themselves.

Default controls:

  - IAM account password policy for any remaining IAM users
  - Account-level S3 Block Public Access
  - EBS encryption by default in the configured region
  - IAM Access Analyzer external access analyzer
  - Root usage alerts through EventBridge and SNS

Root console login alerts require a `us-east-1` EventBridge rule because AWS
records root `ConsoleLogin` events there. Treat that as a security event
listener, not a workload region.

This baseline intentionally skips heavier paid security services for now:

  - Control Tower
  - AWS Config
  - Security Hub
  - GuardDuty
  - Inspector
  - Macie
  - NAT Gateway

Deploy the baseline with your IAM Identity Center developer/admin profile:

  export AWS_PROFILE=robdev
  cd account-baseline
  terraform init
  terraform fmt -recursive
  terraform validate
  terraform plan
  terraform apply

To practice AWS Organizations account inventory from the management account:

  ./scripts/list-org-accounts.sh

Audit Logging
-------------
Use `audit-logging/` from the management account to create:

  - Multi-Region organization CloudTrail for management events
  - Central S3 log bucket
  - S3 public access blocking
  - S3 bucket owner enforced object ownership
  - S3 versioning
  - S3 default encryption
  - Lifecycle retention for current and noncurrent logs
  - CloudTrail log file validation
  - Optional EventBridge/SNS alerts for CloudTrail tampering

This intentionally does not enable CloudTrail data events by default.

Region Guardrails
-----------------
Default AWS Regions cannot be disabled. Opt-in Regions can be disabled, but the
normal way to keep workloads in approved Regions is an AWS Organizations SCP.

Use `organization-guardrails/` from the management account to create an SCP
that denies regional actions outside:

  - us-east-2
  - us-west-2

The policy is not attached by default. Set `target_ids` locally after reviewing
the plan.


Core Decision: Role Or User?
----------------------------
Prefer an IAM role with temporary credentials.

Best local deployment pattern:

  Human AWS identity / IAM Identity Center login
    -> use a dedicated Developer or AccountAdmin permission set
    -> run Terraform locally

Acceptable personal MVP pattern:

  Dedicated IAM user
    -> no console password
    -> access key stored only in a local AWS CLI profile
    -> tightly scoped permissions
    -> rotate/delete when no longer needed

Do not use a general admin IAM user for routine deployments.


Terraform Local Workflow
------------------------
Use Git Bash / POSIX-style commands.

Format all Terraform files:

  terraform fmt -recursive account-baseline audit-logging organization-guardrails

Check formatting without changing files:

  terraform fmt -recursive -check -diff account-baseline audit-logging organization-guardrails

Typical workflow:

  1. Choose the Terraform root you are changing.
  2. Run terraform fmt.
  3. Run terraform init.
  4. Run terraform validate.
  5. Run terraform plan.
  6. Review the plan.
  7. Run terraform apply.
  8. Confirm any SNS email subscriptions.

Example:

  cd account-baseline
  terraform init
  terraform fmt -recursive
  terraform validate
  terraform plan
  terraform apply


Public Repo Safety Checklist
----------------------------
Before pushing anywhere public:

  - Confirm .env is ignored.
  - Confirm *.tfvars is ignored.
  - Confirm *.tfstate and *.tfstate.* are ignored.
  - Confirm no real tokens or API keys exist in committed files.
  - Confirm no real email address is present if privacy matters.
  - Confirm no private repo names or personal project metadata are present if
    privacy matters.
  - Run a secret scanner if possible.

Useful scan:

  git grep -n "AKIA\|github_pat\|OPENAI\|sk-\|arn:aws\|SecretString"


Key Takeaway
------------
Use IAM Identity Center for human access.
Use Terraform to create account baselines, audit logging, and org guardrails.
Keep Terraform state, plan files, local variables, and raw secrets out of GitHub.
