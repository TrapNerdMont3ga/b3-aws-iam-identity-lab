# Access Review Findings and Remediation: Q4 2026

> **SAMPLE: NOT REAL EVIDENCE.** OptiPrim3 is a fictional company and these findings come from
> the example data in `evidence/access-review-Q4-2026.xlsx`. During the AWS build the two main
> findings are reproduced on purpose (see `docs/build-checklist.md`, step 7). Replace this note and
> the screenshot references with real, redacted evidence once it exists.

## Summary

| Item | Value |
|---|---|
| Scope | IAM Identity Center users, groups, permission sets, and account assignments for the OptiPrim3 load-documentation app account |
| Review period | 2026-07-01 to 2026-09-30 |
| Review performed | 2026-10-12 to 2026-10-16 |
| Entitlements reviewed | 8 (7 users, 5 groups) |
| Decisions | 6 Keep, 0 Modify, 2 Revoke |
| Findings | 1 High, 1 Medium, 1 Low |
| Status | High and Medium remediated and verified. Two follow-up actions still open. |

## Findings

### F-Q4-01: Over-privileged user, unapproved admin access (High)

- **User:** `kbrown.dev` (Software Developer)
- **What we found:** On 2026-08-21 the user was added to `CloudAdmins` (AdministratorAccess) in the Identity Center console during an outage. There was no ticket or approval, and the change wasn't in Terraform.
- **Why it matters:** A developer had full admin over the account that holds customer load documents. The 2-admin limit wasn't exceeded, so only the review caught it. Terraform doesn't track memberships it didn't create, so `terraform plan` didn't show it either.
- **Controls:** AC-2, AC-5, AC-6
- **Remediation:** Removed from CloudAdmins on 2026-10-15 (REQ-10566). `scripts/check_membership_drift.py` reports no drift. Verified by the auditor.
- **Recommendations:**
  1. Run the drift check weekly (open, due 2026-11-15).
  2. Write down a break-glass process for outages: a named emergency account, time-boxed, with a ticket opened afterward.
  3. Treat any console change to group membership as a finding until it is reconciled into code.

### F-Q4-02: Stale account, inactive over 90 days (Medium)

- **User:** `tnguyen.helpdesk` (Service Desk Analyst I)
- **What we found:** The last sign-in was 2026-06-24, 116 days before the review. The user is on extended leave, but the account was still enabled with HelpDesk access.
- **Why it matters:** An unused, enabled account is an easy target, and nobody would notice if it were misused.
- **Controls:** AC-2(3)
- **Remediation:** User disabled 2026-10-13 (REQ-10561). Leave-of-absence trigger added to the JML runbook (section 2).
- **Recommendations:** Have HR send leave notices to the service desk as Mover events. Re-enable only through a ticket when the user returns.

### F-Q4-03: Evidence gap, manual last-sign-in data (Low)

- **What we found:** Last-sign-in data was pulled from CloudTrail by hand. There is no saved, repeatable query.
- **Controls:** AC-2(4), AU-6
- **Remediation:** Open (due 2026-12-31).
- **Recommendations:** Save a `aws cloudtrail lookup-events` query in the build checklist and have SecurityAnalysts run it each quarter. Their read-only permission set already allows this.

## Remediation tracker

| Finding | Action | Owner | Status | Evidence |
|---|---|---|---|---|
| F-Q4-01 | Remove `kbrown.dev` from CloudAdmins | Cloud Platform Owner | Done | `screenshots/13-kbrown-groups-after.png`, `screenshots/14-drift-detected.png` |
| F-Q4-01 | Weekly membership drift check | Lamont | In progress | - |
| F-Q4-02 | Disable `tnguyen.helpdesk` | Service Desk Lead | Done | `screenshots/12-tnguyen-disabled.png` |
| F-Q4-02 | Add leave-of-absence trigger to JML runbook | Lamont | Done | `docs/jml-runbook.md` section 2 |
| F-Q4-03 | Saved last-sign-in query | Lamont | Open | - |

## What went well

- Every account assignment is group-based, so each fix was a single membership change.
- All users had MFA registered, and the admin uses a security key.
- No one held both an admin role and a reviewer or monitoring role.
