# AWS IAM Identity Lab: Identity Center, Least Privilege, MFA, and Access Reviews

A hands-on lab that sets up workforce identity in AWS the way a small IT team would run it:
centralized sign-in through **AWS IAM Identity Center**, role-based **permission sets**,
**MFA on every sign-in**, a **joiner/mover/leaver (JML) runbook**, and a **quarterly access review**
with findings and remediation tracking.

Built by Lamont as a portfolio project. Background: about 2 years in IT support, CompTIA Security+,
AWS Certified Cloud Practitioner. The lab is aimed at Service Desk / IT Support Tier 2 and IAM
Analyst work: provisioning, deprovisioning, MFA problems, "why can't I access X", and audit evidence.

> **Status:** Scaffold complete and validated offline (`terraform validate`, `terraform test` with a mocked provider).
> The AWS build and screenshots are pending. See [docs/build-checklist.md](docs/build-checklist.md).

---

## Goal

1. Replace per-user IAM accounts and long-lived access keys with one identity per person, signing in through Identity Center with MFA.
2. Grant access only through **groups mapped to permission sets** so that onboarding, role changes, and offboarding are group membership changes.
3. Give the service desk a **custom least-privilege** permission set that can troubleshoot (view EC2 and IAM) but cannot change or delete anything.
4. Run and document a **quarterly access review** that finds real problems (a stale account, an over-privileged user) and tracks them to closure.

## Architecture

![Architecture](diagrams/architecture.png)

Source: [diagrams/architecture.mmd](diagrams/architecture.mmd) (Mermaid).

| Group | Example users | Permission set | Session | What it allows |
|---|---|---|---|---|
| HelpDesk | jdoe.helpdesk, tnguyen.helpdesk | **HelpDesk** (custom inline policy) | 4h | View EC2, ELB, Auto Scaling, CloudWatch, IAM, Health. Explicit deny on terminate/stop/delete, all IAM writes, SSO/Identity Store writes, Organizations. |
| CloudAdmins | asmith.admin | AdministratorAccess (AWS managed) | **1h** | Full admin. Short session limits exposure. |
| ReadOnlyAuditors | mlee.auditor | ViewOnlyAccess (AWS managed, job function) | 2h | Resource metadata only, no data contents. |
| Developers | rpatel.dev, kbrown.dev | ReadOnlyAccess (AWS managed) | 4h | Read-only access to resources and data. |

All users, emails and IDs are fictional. Account IDs come from `terraform.tfvars`, which is git-ignored.

## Controls demonstrated

| Control | How it shows up in this lab |
|---|---|
| **Least privilege** | Custom HelpDesk permission set with allow-list of view actions plus an explicit `Deny` on destructive and credential-changing actions. Auditors get ViewOnly, not ReadOnly. |
| **MFA** | Identity Center set to prompt for MFA on every sign-in and to require device registration at first sign-in. Admins use a security key (phishing-resistant). |
| **Separation of duties** | Terraform variable validation fails the plan if any user is in both `CloudAdmins` and `ReadOnlyAuditors` (tested in `terraform test`). Reviewers are not the people whose access they review. |
| **Periodic access review** | [evidence/access-review-Q4-2026.xlsx](evidence/access-review-Q4-2026.xlsx): inventory, Keep/Modify/Revoke decisions, findings, remediation, sign-off. |
| **No long-lived credentials** | Users get temporary credentials from the access portal / `aws sso login`. No IAM users or access keys for people. |
| **Group-based access** | Every account assignment targets a group, never an individual user (asserted in `terraform test`). |

## Mapping to NIST SP 800-53 Rev. 5

| Control | Title | Implementation in this lab | Evidence |
|---|---|---|---|
| **AC-2** | Account Management | Accounts created only through the JML runbook with a ticket and manager approval; group-based provisioning in Terraform; leavers disabled within 24h; quarterly review. AC-2(3): accounts inactive 90+ days are disabled. AC-2(4): CloudTrail records identity changes. | `docs/jml-runbook.md`, Q4-Review and Findings sheets, CloudTrail screenshots |
| **AC-6** | Least Privilege | Custom HelpDesk permission set with explicit denies; ViewOnly for auditors; admin limited to one group with 1h sessions. AC-6(5): privileged access restricted to CloudAdmins. AC-6(7): privileges reviewed quarterly. AC-6(9): privileged actions logged in CloudTrail. | `terraform/02-identity-center/permission_sets.tf`, PermissionSets sheet, denied-action screenshot |
| **IA-2** | Identification and Authentication (Organizational Users) | One unique Identity Center user per person; no shared accounts. IA-2(1)/(2): MFA for privileged and non-privileged users. IA-2(8): security keys for admins (replay resistant). | MFA settings screenshot, MFA prompt screenshot |
| **IA-5** | Authenticator Management | Initial password set by the user through a one-time emailed link (no passwords sent by the service desk); AWS-enforced password complexity; MFA device registration and removal handled by runbook with identity verification; temporary credentials instead of access keys. | `docs/jml-runbook.md` (MFA enrollment and reset), Users sheet MFA column |

Related: AC-5 (Separation of Duties) through the SoD validation rule.

## Repository layout

```
.
├── README.md
├── diagrams/
│   ├── architecture.mmd          # Mermaid source
│   └── architecture.png          # rendered diagram
├── docs/
│   ├── build-checklist.md        # exact console/CLI steps + screenshots to capture
│   └── jml-runbook.md            # joiner/mover/leaver service desk SOP
├── evidence/
│   ├── access-review-Q4-2026.xlsx  # EXAMPLE DATA quarterly access review
│   └── build_access_review.py      # regenerates the workbook (openpyxl)
├── screenshots/                  # filled in after the AWS build
├── scripts/
│   └── check_membership_drift.py # flags console-added group memberships
└── terraform/
    ├── 01-billing-alarm/         # deploy FIRST: CloudWatch billing alarm + SNS email (us-east-1)
    └── 02-identity-center/       # groups, users, permission sets, account assignments
        └── tests/offline.tftest.hcl
```

## Build summary

Full steps are in [docs/build-checklist.md](docs/build-checklist.md). In short:

1. **Secure the account and set the cost guardrail first.** MFA on the root user, enable "Receive CloudWatch billing alerts", create a $5 AWS Budget in the console.
2. **Enable IAM Identity Center** (organization instance; this also enables AWS Organizations). Create one manual bootstrap admin user so Terraform can run with temporary SSO credentials instead of access keys.
3. **Configure MFA**: prompt on every sign-in, require registration at first sign-in.
4. **Deploy `terraform/01-billing-alarm`**: CloudWatch `EstimatedCharges >= $5` alarm to an SNS email topic. Confirm the subscription email.
5. **Deploy `terraform/02-identity-center`**: 4 groups, 6 example users, 4 permission sets, group-to-account assignments.
6. **Test as each persona**: sign in as `jdoe.helpdesk`, enroll MFA, confirm EC2/IAM are visible and that terminating an instance or creating an IAM user is denied.
7. **Simulate the review findings**: add `kbrown.dev` to CloudAdmins in the console (drift), catch it with `scripts/check_membership_drift.py` (Terraform's plan won't see it), then remediate. Disable the stale `tnguyen.helpdesk` account.
8. **Complete the access review workbook** and capture screenshots.
9. **Tear down** (below).

Local commands:

```bash
cd terraform/01-billing-alarm
cp terraform.tfvars.example terraform.tfvars   # set alert_email; file is git-ignored
terraform init && terraform plan && terraform apply

cd ../02-identity-center
cp terraform.tfvars.example terraform.tfvars   # set target_account_id
terraform init && terraform test               # offline tests, no AWS calls
terraform plan && terraform apply
```

## Cost

**Expected cost: $0.**

- IAM Identity Center and AWS Organizations have no charge.
- CloudWatch: the first 10 alarms are in the free tier. SNS email notifications: first 1,000 per month are free.
- CloudTrail event history (90 days of management events) is free. No paid trail is created.
- No EC2, RDS, NAT gateways, or other billable resources are created. To test the HelpDesk "deny terminate" behavior you can use a free-tier `t3.micro`/`t2.micro` and terminate it right after the screenshot, or just test the deny on a non-existent instance ID (the IAM decision is made before the resource lookup).
- The billing alarm and a $5 Budget are set **before** anything else is built.

## Teardown

1. `cd terraform/02-identity-center && terraform destroy` removes assignments, permission sets, users, and groups.
2. Terminate any test EC2 instance (if one was launched) and confirm in the EC2 console that nothing is running in any region you used.
3. In Identity Center, delete the manual bootstrap user and `LabBootstrapAdmin` permission set last (after you no longer need CLI access), or keep them if the account stays in use.
4. Optional: Identity Center > Settings > Delete IAM Identity Center configuration.
5. Keep `01-billing-alarm` running (it is free). To remove it: `cd terraform/01-billing-alarm && terraform destroy`.
6. Check Billing > Bills for the month: expected $0.00.

## Screenshots

> **Placeholders.** These files do not exist yet. Capture them during the build (see the checklist), save them in `screenshots/` with these exact names, and redact the account ID, email addresses, and access portal URL before committing.

| # | File | Shows |
|---|---|---|
| 01 | `screenshots/01-root-mfa-enabled.png` | Root user has MFA (Security credentials page) |
| 02 | `screenshots/02-billing-alerts-enabled.png` | Billing preferences: CloudWatch billing alerts on |
| 03 | `screenshots/03-budget-5usd.png` | $5 AWS Budget |
| 04 | `screenshots/04-billing-alarm.png` | CloudWatch alarm `EstimatedCharges >= 5` |
| 05 | `screenshots/05-sns-subscription-confirmed.png` | SNS email subscription status Confirmed |
| 06 | `screenshots/06-identity-center-enabled.png` | Identity Center settings: organization instance, region |
| 07 | `screenshots/07-mfa-settings.png` | MFA: every sign-in, require registration |
| 08 | `screenshots/08-terraform-plan.png` | `terraform plan` for 02-identity-center |
| 09 | `screenshots/09-groups.png` | Identity Center groups list with member counts |
| 10 | `screenshots/10-permission-sets.png` | Permission sets with session durations |
| 11 | `screenshots/11-account-assignments.png` | Account assignments: groups to permission sets |
| 12 | `screenshots/12-tnguyen-disabled.png` | Stale user disabled (finding F-Q4-02) |
| 13 | `screenshots/13-kbrown-groups-after.png` | Over-privileged membership removed (finding F-Q4-01) |
| 14 | `screenshots/14-drift-detected.png` | `scripts/check_membership_drift.py` flagging the console-added admin membership |
| 15 | `screenshots/15-mfa-registration-prompt.png` | First sign-in MFA registration as `jdoe.helpdesk` |
| 16 | `screenshots/16-access-portal-helpdesk.png` | Access portal showing only the HelpDesk role |
| 17 | `screenshots/17-helpdesk-ec2-view.png` | HelpDesk user can view EC2 instances |
| 18 | `screenshots/18-helpdesk-denied.png` | HelpDesk user denied on terminate / create IAM user |
| 19 | `screenshots/19-cloudtrail-identity-events.png` | CloudTrail event history: sign-in and Identity Store events |
| 20 | `screenshots/20-teardown-bill-zero.png` | `terraform destroy` output and $0.00 bill |

## What I learned / talking points

Fill in after the build. Prompts: why group-based access makes offboarding faster; why the HelpDesk set uses an explicit deny; how the review caught console drift; what changes for a 500-person company (SCIM from an IdP such as Entra ID or Okta, automated reviews).

## Security notes

- No secrets, account IDs, state files, or real `*.tfvars` are committed (see `.gitignore`).
- `.terraform.lock.hcl` is committed on purpose so provider versions are pinned.
- All data in `evidence/` is fictional example data and is labeled that way.
