# B3 IAM Identity Lab — Plan of Action and Milestones (POA&M)

- **System:** B3 AWS IAM Identity Lab (fictional OptiPrim3 workforce access). Boundary: [01-system-boundary.md](01-system-boundary.md). Control status: [control-matrix.md](control-matrix.md).
- **Date:** 2026-11-22
- **Status:** Draft for review. Opened after the 2026-11-22 control-set approval (3:28 PM ET).
- **Capacity assumption:** 3–5 lab hours per week, starting the week of 2026-11-23. Thursday 2026-11-26 (Thanksgiving) is a day off, so that week is planned lightly.

Milestones are calendar targets, not commitments to spend. Anything that creates AWS resources with a possible cost (especially a CloudTrail trail and its S3 bucket) stays at plan-only until the account owner approves.

## Summary

| ID | Weakness | Control | Risk | Milestone | Status |
|---|---|---|---|---|---|
| POAM-01 | No CloudTrail trail (Event History only) | AU-2, AU-12 | Medium — management events are visible for 90 days, but there is no durable trail or confirmed multi-region coverage, so audit evidence can lapse. | 2026-12-18 | Open |
| POAM-02 | `tech-operator-lab` IAM user still exists | AC-6(5) | Medium — a standing privileged IAM user is residual admin access outside the Identity Center permission-set model; risk is higher if its access key is still enabled (key state was not recaptured after apply). | 2026-12-07 | Open |
| POAM-03 | SNS budget-alert subscription unconfirmed | Cost guardrail (no direct 800-53 control) | Low — the $5 Budget and CloudWatch alarm exist, but alarm email may not be delivered until SNS is confirmed, and the Budget still does not cap spending. | 2026-11-25 | Open |
| POAM-04 | MFA not confirmed enforced in Identity Center | IA-2(1) | Medium — two test sign-ins used password plus WebAuthn, but the Identity Center MFA enforcement setting has not been confirmed, so password-only access may still be allowed. | 2026-12-02 | Open |

## Items

### POAM-01: No CloudTrail trail

- **Weakness:** The lab relies on CloudTrail Event History only. No trail was found in `us-east-1` when the system boundary was drafted; other regions were not checked. Event History retains management events for 90 days and has no customer-managed log bucket.
- **Control:** AU-2 Event Logging; AU-12 Audit Record Generation.
- **Risk:** Medium — some audit visibility exists (the 2026-10-18 persona denials and sign-in events were retrieved from Event History), but records are not retained beyond 90 days and coverage outside the current region is unconfirmed.
- **Planned remediation:** Design a free-tier-safe trail (management events only; the first copy of management events is typically no CloudTrail charge, but S3 storage is not free). Document the design, get a spend decision if any S3 cost is involved, then implement only after approval. Recapture evidence (trail status, bucket policy, a sample lookup) with identifiers redacted. Do not apply in this pass without that approval.
- **Milestone / target date:** 2026-12-18 (week of 2026-12-14). Placed after the shorter console items so there is time to design and, if needed, ask about spend.
- **Status:** Open
- **Evidence of the weakness:** `compliance/01-system-boundary.md`; `screenshots/19-cloudtrail-event-history.png`; `evidence/cli/12-persona-denied-actions.txt`; `evidence/cli/13-mfa-signin-events.txt`.

### POAM-02: `tech-operator-lab` IAM user still exists

- **Weakness:** Terraform was applied with a dedicated IAM user, `tech-operator-lab` (AdministratorAccess). That user is still listed in the captured caller-identity evidence and is called out as a remaining teardown step. This is the gap that keeps AC-6(5) at Partial.
- **Control:** AC-6(5) Least Privilege | Privileged Accounts.
- **Risk:** Medium — privileged standing access exists outside the Identity Center group and session-duration controls. The evidence does not show whether the access key is still active, so this should be treated as residual admin access until the user and key are gone.
- **Planned remediation:** The account owner deletes the user (this is not to be automated). Deactivate and delete the access key, then delete the user, and confirm with `aws iam list-users` (or the IAM console). Recapture redacted evidence that the user is gone. Do this only after any remaining lab steps that still need that principal, or switch to a different approved method first.
- **Milestone / target date:** 2026-12-07 (week of 2026-12-07). After the SNS and MFA console checks so those steps are not blocked, and before trail work.
- **Status:** Open
- **Evidence of the weakness:** `evidence/cli/00-caller-identity.txt`; `docs/build-checklist.md` (teardown of `tech-operator-lab` still unchecked).

### POAM-03: SNS budget-alert subscription unconfirmed

- **Weakness:** The CloudWatch billing alarm and the $5 monthly Budget were applied, but the SNS email subscription on the billing-alert topic was `PendingConfirmation` in the 2026-10-18 evidence. Until it is confirmed, alarm notifications may not arrive. Separately, the Budget only alerts; it does not cap or stop spend (no budget actions). Confirming SNS closes the notification gap; it does not change the cap limitation, which remains a documented property of this guardrail.
- **Control:** Cost guardrail (no direct 800-53 control).
- **Risk:** Low — the alarm (state OK) and Budget objects exist, so the remaining issue is notification delivery, not absence of a threshold. Overruns could still go unnoticed if mail is not confirmed, and spend would not be blocked in any case.
- **Planned remediation:** The account owner confirms the SNS subscription from the subscription email (or resubscribes if the link expired). Recapture `evidence/cli/08-sns-subscription.txt` showing a confirmed subscription (endpoint remains redacted). Optional: capture pending screenshot `screenshots/05-sns-subscription-confirmed.png`, with identifiers redacted.
- **Milestone / target date:** 2026-11-25 (week of 2026-11-23; Wednesday, before Thanksgiving). This is a short confirmation step and is scheduled first.
- **Status:** Open
- **Evidence of the weakness:** `evidence/cli/08-sns-subscription.txt` (`PendingConfirmation`); `evidence/cli/07-billing-alarm.txt`; `evidence/cli/09-budget.txt`; `terraform/01-billing-alarm/main.tf`.

### POAM-04: MFA not confirmed enforced

- **Weakness:** Identity Center MFA enforcement (prompt on every sign-in; require device registration at first sign-in) has not been confirmed. The planned evidence file `screenshots/07-mfa-settings.png` was never captured. Two fictional personas enrolled a device and later signed in with `CredentialType=PASSWORD,WEBAUTHN`, which shows MFA was used for those tests, not that the org-level setting is enforced for every user.
- **Control:** IA-2(1) Identification and Authentication (Organizational Users) | Multi-Factor Authentication.
- **Risk:** Medium — test sign-ins used WebAuthn, but without a confirmed always-on MFA policy, password-only access may still be possible, including for privileged permission sets.
- **Planned remediation:** The account owner opens IAM Identity Center > Settings > Authentication and confirms (or sets) MFA on every sign-in and required registration at first sign-in. Capture a redacted screenshot as `screenshots/07-mfa-settings.png`. Once that evidence exists, IA-2(1) can move from Planned to Implemented in the control matrix; until then it stays Planned.
- **Milestone / target date:** 2026-12-02 (week of 2026-11-30). A single console session after the Thanksgiving week; needs the account owner's login.
- **Status:** Open
- **Evidence of the weakness:** Missing `screenshots/07-mfa-settings.png`. Supporting test records (not enforcement): `evidence/cli/13-mfa-signin-events.txt`; `screenshots/19-cloudtrail-event-history.png`.
