# B3 IAM Identity Lab — Plan of Action and Milestones (POA&M)

- **System:** B3 AWS IAM Identity Lab (fictional OptiPrim3 workforce access). Boundary: [01-system-boundary.md](01-system-boundary.md). Control status: [control-matrix.md](control-matrix.md).
- **Date:** 2026-11-22
- **Status:** Updated 2026-11-22 after evidence capture. Two items closed; three remain open. POAM-05 MFA is complete; that item stays open only for access-key confirmation.
- **Capacity assumption:** 3–5 lab hours per week, starting the week of 2026-11-23. Thursday 2026-11-26 (Thanksgiving) is a day off, so that week is planned lightly.

Milestones are calendar targets, not commitments to spend. Anything that creates AWS resources with a possible cost (especially a CloudTrail trail and its S3 bucket) stays at plan-only until the account owner approves.

## Summary

| ID | Weakness | Control | Risk | Milestone | Status |
|---|---|---|---|---|---|
| POAM-01 | No CloudTrail trail (Event History only) | AU-2, AU-12 | Medium — management events are visible for 90 days, but there is no durable trail or confirmed multi-region coverage, so audit evidence can lapse. | 2026-12-18 | Open |
| POAM-02 | `tech-operator-lab` IAM user still exists | AC-6(5) | Medium — a standing privileged IAM user is residual admin access outside the Identity Center permission-set model; risk is higher if its access key is still enabled (key state was not recaptured after apply). | 2026-12-07 | Closed 2026-11-22 |
| POAM-03 | SNS budget-alert subscription unconfirmed | Cost guardrail (no direct 800-53 control) | Low — the $5 Budget and CloudWatch alarm exist, but alarm email may not be delivered until SNS is confirmed, and the Budget still does not cap spending. | 2026-11-25 | Open |
| POAM-04 | MFA not confirmed enforced in Identity Center | IA-2(1) | Medium — two test sign-ins used password plus WebAuthn, but the Identity Center MFA enforcement setting has not been confirmed, so password-only access may still be allowed. | 2026-12-02 | Closed 2026-11-22 |
| POAM-05 | `trapnerd-admin` long-term access key not confirmed deactivated or removed | AC-6(5), AC-2 | Medium-High — a passkey MFA device is now assigned, but the user summary still shows Access key 1; access keys bypass console MFA and remain standing privileged credentials until deactivated or deleted. | 2026-12-07 | Open |

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

- **Weakness:** Terraform was applied with a dedicated IAM user, `tech-operator-lab` (AdministratorAccess). That user was still listed in the captured caller-identity evidence and was called out as a remaining teardown step. This was the gap that originally kept AC-6(5) at Partial.
- **Control:** AC-6(5) Least Privilege | Privileged Accounts.
- **Risk:** Medium — privileged standing access existed outside the Identity Center group and session-duration controls. The earlier evidence did not show whether the access key was still active, so it was treated as residual admin access until the user was gone.
- **Remediation:** The account owner (Lamont) deleted the `tech-operator-lab` IAM user on 2026-11-22. The IAM users list after deletion shows `trapnerd-admin` and `trapnerdMont3ga` only. AC-6(5) remains Partial because `trapnerd-admin` still has a long-term access key that has not been confirmed deactivated or removed; that remaining gap is tracked as [POAM-05](#poam-05-trapnerd-admin-access-key-still-present).
- **Milestone / target date:** 2026-12-07 (closed early, 2026-11-22).
- **Status:** Closed 2026-11-22
- **Evidence of closure:** `screenshots/poam-02-delete-tech-operator-lab-confirm.png` (delete confirmation for `tech-operator-lab`); `screenshots/poam-02-tech-operator-lab-deleted.png` (success banner, and the user is no longer in the IAM users list). Earlier evidence of the weakness: `evidence/cli/00-caller-identity.txt`; `docs/build-checklist.md`.

### POAM-03: SNS budget-alert subscription unconfirmed

- **Weakness:** The CloudWatch billing alarm and the $5 monthly Budget were applied, but the SNS email subscription on the billing-alert topic was `PendingConfirmation` in the 2026-10-18 evidence. Until it is confirmed, alarm notifications may not be delivered. Separately, the Budget only alerts; it does not cap or stop spend (no budget actions). Confirming SNS closes the notification-confirmation gap; it does not change the cap limitation, which remains a documented property of this guardrail.
- **Control:** Cost guardrail (no direct 800-53 control).
- **Risk:** Low — the alarm (state OK) and Budget objects exist, so the remaining issue is formal confirmation of the SNS subscription, not absence of a threshold. Overruns could still go unnoticed if the confirmation step is incomplete, and spend would not be blocked in any case.
- **Planned remediation:** The account owner confirms the SNS subscription from the subscription email (or resubscribes if the link expired). Recapture `evidence/cli/08-sns-subscription.txt` showing a confirmed subscription (endpoint remains redacted). Optional: capture pending screenshot `screenshots/05-sns-subscription-confirmed.png`, with identifiers redacted.
- **Update (2026-11-22):** A budget alert email was received on 2026-11-11 (`screenshots/poam-03-budget-alert-email.png`). That shows the alert path works — the $5 budget forecast alert fired and arrived in email. The SNS subscription confirmation screenshot (`screenshots/05-sns-subscription-confirmed.png`) is still pending, so this item stays Open. The forecast exceedance in that email was caused by a non-lab AWS Skill Builder subscription, which is being cancelled.
- **Milestone / target date:** 2026-11-25 (week of 2026-11-23; Wednesday, before Thanksgiving). This is a short confirmation step and is scheduled first.
- **Status:** Open
- **Evidence of the weakness:** `evidence/cli/08-sns-subscription.txt` (`PendingConfirmation`); `evidence/cli/07-billing-alarm.txt`; `evidence/cli/09-budget.txt`; `terraform/01-billing-alarm/main.tf`. Evidence that the alert path works, pending SNS confirmation: `screenshots/poam-03-budget-alert-email.png`.

### POAM-04: MFA not confirmed enforced

- **Weakness:** Identity Center MFA enforcement (prompt on every sign-in; require device registration at first sign-in) had not been confirmed. The originally planned evidence file `screenshots/07-mfa-settings.png` had not been captured. Two fictional personas enrolled a device and later signed in with `CredentialType=PASSWORD,WEBAUTHN`, which showed MFA was used for those tests, not that the org-level setting was enforced for every user.
- **Control:** IA-2(1) Identification and Authentication (Organizational Users) | Multi-Factor Authentication.
- **Risk:** Medium — test sign-ins used WebAuthn, but without a confirmed always-on MFA policy, password-only access may still have been possible, including for privileged permission sets.
- **Remediation:** The account owner opened IAM Identity Center > Settings > Authentication and confirmed MFA is set to "Every time they sign in (always-on)" and "Require them to register an MFA device at sign in". Allowed methods are authenticator apps, security keys, and built-in authenticators; users and administrators can add and manage MFA devices. Evidence was captured as `screenshots/poam-04-identity-center-mfa-always-on.png`, which replaces the planned `screenshots/07-mfa-settings.png` path. IA-2(1) is Implemented for Identity Center sign-ins. A passkey was later assigned to the remaining IAM user `trapnerd-admin` (IA-2(1) for that user is complete); the leftover access key is tracked as [POAM-05](#poam-05-trapnerd-admin-access-key-still-present).
- **Milestone / target date:** 2026-12-02 (closed early, 2026-11-22).
- **Status:** Closed 2026-11-22
- **Evidence of closure:** `screenshots/poam-04-identity-center-mfa-always-on.png` (Identity Center Settings > Authentication: always-on MFA, required device registration at sign-in, allowed device types, and user/admin device management). Supporting test records: `evidence/cli/13-mfa-signin-events.txt`; `screenshots/19-cloudtrail-event-history.png`.

### POAM-05: `trapnerd-admin` access key still present

- **Weakness:** The IAM user `trapnerd-admin` remains in the account. It is admin-named and uses long-term IAM credentials (not Identity Center temporary credentials). Last activity was 14 days before 2026-11-22 (about 2026-11-08). The MFA gap is closed; the remaining weakness is a long-term access key.
- **Control:** AC-6(5) Least Privilege | Privileged Accounts; AC-2 Account Management. (IA-2(1) for this user is addressed by the passkey assignment below.)
- **Risk:** Medium-High — Access key 1 is still shown on the user summary. Access keys are long-term credentials and are not protected by the passkey MFA device, so a compromised key would still give standing privileged access.
- **Remediation (MFA, complete):** The account owner (Lamont) assigned a passkey MFA device to `trapnerd-admin` on 2026-11-22. Evidence: `screenshots/poam-05-trapnerd-admin-passkey-mfa-assigned.png` (banner "Passkey MFA device assigned"; user `trapnerd-admin`; account alias Optiprim3).
- **Remaining remediation:** Confirm that Access key 1 on `trapnerd-admin` is deactivated or deleted (or retire the user in favor of Identity Center and remove its keys). Recapture redacted evidence of the key state. This item stays Open until that confirmation.
- **Milestone / target date:** 2026-12-07 (week of 2026-12-07). Same window as the original privileged-user teardown (POAM-02).
- **Status:** Open (MFA complete 2026-11-22; open for access-key confirmation)
- **Evidence:** MFA complete: `screenshots/poam-05-trapnerd-admin-passkey-mfa-assigned.png`. Earlier weakness (blank MFA column, before the passkey was assigned): `screenshots/poam-02-tech-operator-lab-deleted.png`. The passkey screenshot also shows the Summary labels ARN, Console access, and Access key 1; values were cropped off the bottom of the frame, so key status is not yet evidenced.
