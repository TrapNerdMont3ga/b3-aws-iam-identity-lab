# B3 IAM Identity Lab — System Security Plan (lite)

- **Date:** 2026-11-23
- **Status:** Draft. This is a short system-security-plan summary for a portfolio lab, not a formal authorization package.
- **Rule:** Only claim what was actually built. Current control status lives in [control-matrix.md](control-matrix.md). Open and closed weaknesses live in [poam.md](poam.md).
- **Related:** [01-system-boundary.md](01-system-boundary.md), [cloudtrail-trail-design.md](cloudtrail-trail-design.md).

## 1. System name and purpose

**System name:** B3 AWS IAM Identity Lab (fictional OptiPrim3 workforce access).

**Purpose:** Demonstrate least-privilege workforce access on AWS using IAM Identity Center and Terraform, with honest evidence against a small NIST SP 800-53 Rev. 5 control set. OptiPrim3 is a fictional practice company. This lab is a training and portfolio system, not a production corporate environment.

## 2. System owner

**Role:** Account owner / system owner of the lab AWS account.

The owner approves any apply or spend, accepts residual risk that is recorded in the POA&M, and performs console steps that are not automated (for example, deleting a leftover IAM user, confirming an SNS subscription, and rotating a long-term access key). This plan does not record personal contact details.

## 3. Authorization boundary

The in-scope boundary is the AWS target compliance environment described in [01-system-boundary.md](01-system-boundary.md) (draft, 2026-11-08): IAM Identity Center, MFA sign-in, the lab users and groups, permission sets, the Terraform modules that define them, and the billing alarm and $5 monthly Budget.

**Out of scope:** the corporate network, real company or driver data, EC2, networking, in-cabin ELD / GPS hardware, and telematics provider APIs. Those items appear in the boundary diagram only as context. The telematics connection has not been built.

## 4. System components (built)

| Component | What it is | How it is managed |
|---|---|---|
| IAM Identity Center (organization instance) | Workforce sign-in and permission-set sessions | Terraform module `terraform/02-identity-center/` plus console MFA settings |
| Users and groups | Fictional workforce identities (HelpDesk, SecurityAnalyst, and related lab personas) assigned through groups | Terraform; membership drift checked by `scripts/check_membership_drift.py` |
| Permission sets | Custom HelpDesk and SecurityAnalyst sets with allow-lists and explicit denies; AdministratorAccess and ViewOnlyAccess with session-duration limits | Terraform; offline `terraform test`; live policy simulator and persona denials |
| Billing guardrail | CloudWatch estimated-charges alarm and a $5 monthly AWS Budget, with a confirmed SNS email subscription | Terraform module `terraform/01-billing-alarm/` |
| CloudTrail Event History | Default 90-day management-event history used for lab evidence | AWS default; **no trail is applied yet** |
| Documentation and evidence | Control matrix, POA&M, JML runbook, permission-set matrix, redacted screenshots and CLI output | GitHub repository (public); identifiers are redacted in published files |

**Designed, not built:** a CloudTrail management-events trail and private log bucket (`terraform/03-cloudtrail/`, [cloudtrail-trail-design.md](cloudtrail-trail-design.md)). The module default is `enable_cloudtrail = false`. It must not be applied until the owner approves a plan.

**Still present, residual:** a privileged IAM user (`trapnerd-admin`) with a long-term access key used for the owner's AWS-hosted website, which is outside this lab's application boundary. Console MFA (passkey) is enabled on that user. The residual access-key risk was accepted by the owner on 2026-11-22 (POAM-05).

## 5. Data types

In scope, the lab holds **fictional and operational metadata only**:

- Fictional user names, group memberships, and example email addresses used for personas
- AWS configuration (permission sets, assignments, budget and alarm settings)
- Audit evidence of lab activity (CloudTrail Event History, screenshots, CLI output)
- Billing and budget notification metadata

The lab does **not** process real customer, driver, payment, or health data. Published evidence is reviewed so account IDs, Identity Center instance IDs, emails, and similar identifiers are replaced or blurred.

## 6. Roles

| Role | Path | What it can do (built) |
|---|---|---|
| Account owner / system owner | Console and break-glass IAM, plus Identity Center admin as configured | Approves spend and apply; records risk acceptance; rotates the residual access key |
| CloudAdmins | Identity Center permission set, 1-hour AdministratorAccess sessions, membership capped in Terraform | Full admin inside the cap and session limit |
| HelpDesk | Custom permission set | Limited read / support actions; explicit denies on identity administration, billing, and similar out-of-role APIs (proven by denial screenshots) |
| SecurityAnalyst | Custom permission set | Logs and findings-oriented access; cannot create a CloudTrail trail or inspect infrastructure inventory (proven by denial screenshots) |
| ReadOnlyAuditors | ViewOnly plus an optional evidence-prefix read | Review evidence; no change access |
| Fictional workforce users | Identity Center users in groups; no long-lived access keys for those personas | Temporary credentials through the access portal |

## 7. Interconnections

**None built.** There is no production application, no telematics feed, no corporate IdP (no SCIM from Entra ID or Okta), and no trust to another AWS account that this plan treats as in-scope. Users reach the Identity Center access portal and the AWS Management Console over HTTPS. The owner's separate AWS-hosted website is an operational dependency of a residual IAM user (POAM-05); it is not an in-scope interconnection of this lab system.

## 8. Control implementation summary

The system is assessed against the 11-row NIST SP 800-53 Rev. 5 set in [control-matrix.md](control-matrix.md). That matrix is the status of record.

As of 2026-11-23:

- **Implemented (7):** AC-2 Account Management; AC-3 Access Enforcement; AC-6 Least Privilege; IA-2 Identification and Authentication; IA-2(1) MFA (Identity Center always-on, and a passkey on the remaining IAM user); CM-2 Baseline Configuration; identifier-redaction process (SI-12 / SA-8(33)).
- **Partial (4):** AC-6(5) Privileged Accounts (standing IAM user and access key remain; residual risk accepted); AU-2 Event Logging and AU-12 Audit Record Generation (Event History only; a trail is designed but not applied); cost guardrail (the $5 budget alerts and SNS is confirmed, but spend is not capped).
- **Planned (0).**

Do not treat the earlier README documentation crosswalk as the approval record.

## 9. Plan of action and milestones

Weaknesses, closures, and residual-risk acceptance are tracked in [poam.md](poam.md). As of 2026-11-23, POAM-02, POAM-03, POAM-04, and POAM-05 are closed (POAM-05 as risk accepted, with a scheduled quarterly key-rotation reminder). **POAM-01 remains open:** a CloudTrail trail design is drafted and is waiting for owner approval before apply.

## 10. Revision

| Date | Change |
|---|---|
| 2026-11-23 | Initial SSP-lite, limited to built components and documented residual risk. |
