# B3 IAM Identity Lab — Plan of Action and Milestones (POA&M)

- **System:** B3 AWS IAM Identity Lab (fictional OptiPrim3 workforce access). Boundary: [01-system-boundary.md](01-system-boundary.md). Control status: [control-matrix.md](control-matrix.md).
- **Date:** 2026-11-24
- **Status:** Updated 2026-11-24. All five items are closed. POAM-01 closed 2026-11-24 (trail applied 2026-11-23; evidence captured 2026-11-24). POAM-02, POAM-03, and POAM-04 closed 2026-11-22. POAM-05 closed 2026-11-22 (risk accepted by the owner).
- **Capacity assumption:** 3–5 lab hours per week, starting the week of 2026-11-23. Thursday 2026-11-26 (Thanksgiving) is a day off, so that week is planned lightly.

Milestones are calendar targets, not commitments to spend. Further AWS resources with a possible cost stay at plan-only until the account owner approves.

## Summary

| ID | Weakness | Control | Risk | Milestone | Status |
|---|---|---|---|---|---|
| POAM-01 | No CloudTrail trail (Event History only) | AU-2, AU-12 | Medium — management events were visible for 90 days in Event History only, with no durable trail or confirmed multi-region coverage, so audit evidence could lapse. | 2026-12-18 | Closed 2026-11-24 |
| POAM-02 | `tech-operator-lab` IAM user still exists | AC-6(5) | Medium — a standing privileged IAM user is residual admin access outside the Identity Center permission-set model; risk is higher if its access key is still enabled (key state was not recaptured after apply). | 2026-12-07 | Closed 2026-11-22 |
| POAM-03 | SNS budget-alert subscription unconfirmed | Cost guardrail (no direct 800-53 control) | Low — the $5 Budget and CloudWatch alarm exist, but alarm email may not be delivered until SNS is confirmed, and the Budget still does not cap spending. | 2026-11-25 | Closed 2026-11-22 |
| POAM-04 | MFA not confirmed enforced in Identity Center | IA-2(1) | Medium — two test sign-ins used password plus WebAuthn, but the Identity Center MFA enforcement setting has not been confirmed, so password-only access may still be allowed. | 2026-12-02 | Closed 2026-11-22 |
| POAM-05 | `trapnerd-admin` long-term access key used for an AWS-hosted website | AC-6(5), AC-2 | Medium-High — access keys bypass console MFA; accepted by the owner because the key is a documented operational dependency for the website and console MFA (passkey) is in place. | 2026-12-07 | Closed 2026-11-22 (risk accepted) |

## Items

### POAM-01: No CloudTrail trail

- **Weakness:** The lab relied on CloudTrail Event History only. No trail was found in `us-east-1` when the system boundary was drafted; other regions were not checked. Event History retains management events for 90 days and has no customer-managed log bucket.
- **Control:** AU-2 Event Logging; AU-12 Audit Record Generation. The design also addresses AU-3, AU-6, AU-9, and AU-11, which are not current matrix rows (see the design document).
- **Risk:** Medium — some audit visibility existed (the 2026-10-18 persona denials and sign-in events were retrieved from Event History), but records were not retained beyond 90 days in an owner-controlled store and coverage outside the current region was unconfirmed.
- **Remediation:** The account owner applied the CloudTrail module on 2026-11-23. The applied configuration is one multi-Region trail (`b3-iam-lab-management-events`), management events only, no data events, no Lake or Insights, delivery to a private SSE-S3 bucket (not KMS) with Block Public Access On, a CloudTrail-only bucket policy constrained by `aws:SourceArn`, log-file validation enabled, SNS notification delivery Disabled, CloudWatch Logs off, and a 90-day lifecycle rule (`expire-cloudtrail-logs`, entire bucket). The Terraform module default remains `enable_cloudtrail = false` so a later apply from a clean checkout does not create a second trail. AU-2 and AU-12 are Implemented. See [cloudtrail-trail-design.md](cloudtrail-trail-design.md).
- **Milestone / target date:** 2026-12-18 (closed early, 2026-11-24; applied 2026-11-23).
- **Status:** Closed 2026-11-24
- **Evidence of the weakness:** `compliance/01-system-boundary.md`; `screenshots/19-cloudtrail-event-history.png`; `evidence/cli/12-persona-denied-actions.txt`; `evidence/cli/13-mfa-signin-events.txt`.
- **Evidence of closure:** `screenshots/poam-01-cloudtrail-trail-details.png` (logging on, multi-Region, validation enabled, SSE-KMS not enabled, SNS notification delivery disabled; last log file delivered November 24, 2026, 21:05:57 (UTC-05:00) — this is the log-delivery evidence); `screenshots/poam-01-cloudtrail-management-events.png` (API activity All); `screenshots/poam-01-cloudtrail-block-public-access.png`; `screenshots/poam-01-cloudtrail-default-encryption-sse-s3.png`; `screenshots/poam-01-cloudtrail-bucket-policy.png` (account ID replaced with placeholder); `screenshots/poam-01-cloudtrail-lifecycle-90d.png`; `screenshots/poam-01-cloudtrail-digest-log-file-validation.png` (a `CloudTrail-Digest` object from 2026-11-23 — this proves log file validation, not delivery by itself). Treat the trail-details screenshot plus the digest screenshot as delivery and validation evidence. A `CloudTrail/` log-object screenshot is optional future evidence. Design and module: [cloudtrail-trail-design.md](cloudtrail-trail-design.md); `terraform/03-cloudtrail/`.

### POAM-02: `tech-operator-lab` IAM user still exists

- **Weakness:** Terraform was applied with a dedicated IAM user, `tech-operator-lab` (AdministratorAccess). That user was still listed in the captured caller-identity evidence and was called out as a remaining teardown step. This was the gap that originally kept AC-6(5) at Partial.
- **Control:** AC-6(5) Least Privilege | Privileged Accounts.
- **Risk:** Medium — privileged standing access existed outside the Identity Center group and session-duration controls. The earlier evidence did not show whether the access key was still active, so it was treated as residual admin access until the user was gone.
- **Remediation:** The account owner (Lamont) deleted the `tech-operator-lab` IAM user on 2026-11-22. The IAM users list after deletion shows `trapnerd-admin` and `trapnerdMont3ga` only. AC-6(5) remains Partial because `trapnerd-admin` still has a long-term access key (a documented operational dependency for the owner's AWS-hosted website). That residual risk was accepted by the owner on 2026-11-22; see [POAM-05](#poam-05-trapnerd-admin-access-key-still-present).
- **Milestone / target date:** 2026-12-07 (closed early, 2026-11-22).
- **Status:** Closed 2026-11-22
- **Evidence of closure:** `screenshots/poam-02-delete-tech-operator-lab-confirm.png` (delete confirmation for `tech-operator-lab`); `screenshots/poam-02-tech-operator-lab-deleted.png` (success banner, and the user is no longer in the IAM users list). Earlier evidence of the weakness: `evidence/cli/00-caller-identity.txt`; `docs/build-checklist.md`.

### POAM-03: SNS budget-alert subscription unconfirmed

- **Weakness:** The CloudWatch billing alarm and the $5 monthly Budget were applied, but the SNS email subscription on the billing-alert topic was `PendingConfirmation` in the 2026-10-18 evidence. Until it was confirmed, alarm notifications may not have been delivered. Separately, the Budget only alerts; it does not cap or stop spend (no budget actions). Confirming SNS closes the notification-confirmation gap; it does not change the cap limitation, which remains a documented property of this guardrail and is why the cost-guardrail row stays Partial.
- **Control:** Cost guardrail (no direct 800-53 control).
- **Risk:** Low — the alarm (state OK) and Budget objects exist. The remaining issue before confirmation was formal confirmation of the SNS subscription, not absence of a threshold. Spend is still not blocked by the Budget.
- **Remediation:** The account owner (Lamont) confirmed the SNS subscription on 2026-11-22. The subscription page shows Status: Confirmed for topic `b3-iam-lab-billing-alerts`. A budget alert email received on 2026-11-11 had already shown that the alert path can deliver mail; this screenshot closes the confirmation gap. The forecast exceedance in that email was caused by a non-lab AWS Skill Builder subscription, which is being cancelled.
- **Milestone / target date:** 2026-11-25 (closed early, 2026-11-22).
- **Status:** Closed 2026-11-22
- **Evidence of closure:** `screenshots/poam-03-sns-subscription-confirmed.png` (SNS subscription Status: Confirmed; ARN and endpoint redacted; subscription UUID in the title and breadcrumb left visible). Supporting alert-path evidence: `screenshots/poam-03-budget-alert-email.png`. Earlier evidence of the weakness: `evidence/cli/08-sns-subscription.txt` (`PendingConfirmation`); `evidence/cli/07-billing-alarm.txt`; `evidence/cli/09-budget.txt`; `terraform/01-billing-alarm/main.tf`.

### POAM-04: MFA not confirmed enforced

- **Weakness:** Identity Center MFA enforcement (prompt on every sign-in; require device registration at first sign-in) had not been confirmed. The originally planned evidence file `screenshots/07-mfa-settings.png` had not been captured. Two fictional personas enrolled a device and later signed in with `CredentialType=PASSWORD,WEBAUTHN`, which showed MFA was used for those tests, not that the org-level setting was enforced for every user.
- **Control:** IA-2(1) Identification and Authentication (Organizational Users) | Multi-Factor Authentication.
- **Risk:** Medium — test sign-ins used WebAuthn, but without a confirmed always-on MFA policy, password-only access may still have been possible, including for privileged permission sets.
- **Remediation:** The account owner opened IAM Identity Center > Settings > Authentication and confirmed MFA is set to "Every time they sign in (always-on)" and "Require them to register an MFA device at sign in". Allowed methods are authenticator apps, security keys, and built-in authenticators; users and administrators can add and manage MFA devices. Evidence was captured as `screenshots/poam-04-identity-center-mfa-always-on.png`, which replaces the planned `screenshots/07-mfa-settings.png` path. IA-2(1) is Implemented for Identity Center sign-ins. A passkey was later assigned to the remaining IAM user `trapnerd-admin` (IA-2(1) for that user is complete). The leftover access key is a documented website dependency; that residual risk was accepted by the owner on 2026-11-22 (see [POAM-05](#poam-05-trapnerd-admin-access-key-still-present)).
- **Milestone / target date:** 2026-12-02 (closed early, 2026-11-22).
- **Status:** Closed 2026-11-22
- **Evidence of closure:** `screenshots/poam-04-identity-center-mfa-always-on.png` (Identity Center Settings > Authentication: always-on MFA, required device registration at sign-in, allowed device types, and user/admin device management). Supporting test records: `evidence/cli/13-mfa-signin-events.txt`; `screenshots/19-cloudtrail-event-history.png`.

### POAM-05: `trapnerd-admin` access key still present

- **Weakness:** The IAM user `trapnerd-admin` remains in the account. It is admin-named and uses long-term IAM credentials (not Identity Center temporary credentials), including Access key 1, which is in use for the owner's AWS-hosted website. Last activity was 14 days before 2026-11-22 (about 2026-11-08). Access keys bypass console MFA.
- **Control:** AC-6(5) Least Privilege | Privileged Accounts; AC-2 Account Management. (IA-2(1) for this user is addressed by the passkey assignment.)
- **Risk:** Medium-High — a compromised access key would still give standing privileged access, because access keys are not protected by the passkey MFA device.
- **Remediation (MFA, complete):** The account owner (Lamont) assigned a passkey MFA device to `trapnerd-admin` on 2026-11-22, so console access is MFA-enforced. Evidence: `screenshots/poam-05-trapnerd-admin-passkey-mfa-assigned.png`.
- **Risk acceptance (access key):** Closed as risk accepted by the owner on 2026-11-22. Rationale: MFA is enforced for console access; the access key is a documented operational dependency for the owner's AWS-hosted website; access keys bypass MFA, and that residual risk is accepted rather than removing the key at this time.
- **Compensating controls / recommended follow-up (not commitments):** Rotate the key at least every 90 days; scope it to least privilege for the website only; plan to move the site to an IAM role or a dedicated, narrowly scoped user. These are recommended follow-ups, not dated remediation commitments. A quarterly key-rotation reminder is now scheduled for the 1st of March, June, September, and December, starting 2026-12-01. The account owner rotates the key. Evidence for each rotation is a redacted access-keys screenshot.
- **Milestone / target date:** 2026-12-07 (closed 2026-11-22 as risk accepted).
- **Status:** Closed 2026-11-22 (risk accepted)
- **Evidence:** MFA complete: `screenshots/poam-05-trapnerd-admin-passkey-mfa-assigned.png`. Earlier view (blank MFA column, before the passkey was assigned): `screenshots/poam-02-tech-operator-lab-deleted.png`. The passkey screenshot also shows the Summary label Access key 1 (values were cropped off the bottom of the frame). The owner stated on 2026-11-22 that this access key is in use for the AWS-hosted website.
