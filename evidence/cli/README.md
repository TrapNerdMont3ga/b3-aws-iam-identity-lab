# CLI evidence: live deployment (2026-10-18)

Read-only AWS CLI output captured right after `terraform apply`. The account ID is shown as
`<ACCOUNT_ID>` and the alert email as `<ALERT_EMAIL>`. No credentials appear in these files.
Regenerate with `bash scripts/verify_identity_center.sh <account-id>`.

| File | Proves |
|---|---|
| 00-caller-identity.txt | Which principal ran Terraform (temporary IAM user) |
| 01-sso-instance.txt | Identity Center organization instance, us-east-1, permission sets enabled |
| 02-groups.txt / 03-users.txt | 5 groups and 7 fictional users exist |
| 04-group-memberships.txt | Memberships match Terraform |
| 05-permission-sets.txt | Session durations, managed policies, full inline policies |
| 06-account-assignments.txt | Group-only assignments, provisioned to the account (SUCCEEDED) |
| 07 / 08 / 09 | Billing alarm (OK), SNS email subscription, $5 monthly Budget |
| 10-membership-drift-check.txt | Live memberships == Terraform (no drift) |
| 11-policy-simulator.txt | IAM policy simulator: reads allowed, destructive actions explicitly denied |
