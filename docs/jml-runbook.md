# OptiPrim3 SOP: AWS Access - Joiner / Mover / Leaver (JML)

| Field | Value |
|---|---|
| SOP ID | IAM-SOP-001 |
| Version | 1.0 (lab) |
| Owner | Service Desk Lead |
| Approver | IT Manager / Cloud Platform Owner |
| Applies to | AWS IAM Identity Center users, groups, and account assignments for the OptiPrim3 load-documentation app account |
| Related controls | NIST 800-53 AC-2, AC-2(3), AC-5, AC-6, IA-2(1), IA-5 |
| Review cycle | Annually, or after any finding from the quarterly access review |

> Lab note: OptiPrim3 is a fictional logistics company. Names, ticket numbers, and approvers are examples. Group-to-permission-set details: [permission-set-matrix.md](permission-set-matrix.md).

## 1. Purpose

Give people the AWS access their job needs on day one, change it when their job changes, and remove
it quickly when they leave. Every change is ticketed, approved, done through a group (never a direct
user assignment), verified, and leaves evidence for the quarterly access review.

## 2. Triggers

| Event | Trigger source | Ticket type |
|---|---|---|
| **Joiner**: new hire, contractor start, rehire | HR onboarding notice or manager request | Service Request: *AWS Access - New User* |
| **Mover**: role change, team transfer, temporary elevated access, return from leave | HR change notice or manager request | Service Request: *AWS Access - Change* |
| **Leaver**: resignation, termination, contract end | HR termination notice (or Security for urgent termination) | Service Request: *AWS Access - Removal* (Priority P2; P1 if involuntary) |
| **Leave of absence > 30 days** | HR leave notice | *AWS Access - Change* (disable, do not delete) |
| **Access review Revoke/Modify decision** | Quarterly access review | *AWS Access - Change* or *Removal*, linked to the review ID |

The service desk does not act on access requests received by chat, phone, or personal email. Ask the
requester to open a ticket.

## 3. Required ticket fields

| Field | Joiner | Mover | Leaver |
|---|---|---|---|
| Employee full name and employee ID | Required | Required | Required |
| Username (format `first-initial+last.role`, e.g. `jdoe.helpdesk`) | Assigned by service desk | Existing | Existing |
| Work email | Required | - | - |
| Job title / department | Required | New and old | - |
| Manager | Required | New and old | Required |
| Start / effective / last-day date and time (with time zone) | Start date | Effective date | Last day + time |
| Requested group(s) | Required | Groups to add **and** remove | All (remove) |
| Business justification | Required | Required | - |
| Approvals (see section 4) | Attached | Attached | HR notice attached |
| Temporary access end date | If temporary | If temporary | - |

## 4. Approvals

| Access requested | Approver(s) |
|---|---|
| HelpDesk, Developers | User's manager |
| SecurityAnalysts | User's manager **and** Security Lead |
| ReadOnlyAuditors | Compliance Manager |
| CloudAdmins (AdministratorAccess) | User's manager **and** Cloud Platform Owner. Rejected if CloudAdmins is already at the limit (`max_admins`, default 2) unless someone is removed in the same change. |
| ReadOnlyAuditors or SecurityAnalysts for someone in CloudAdmins (or the reverse) | Not allowed (separation of duties). Reject the request. Terraform also blocks it. |
| Leaver / removal | No approval needed. HR notice or Security request is the authority. |

Approvals must be recorded in the ticket by the approver (not forwarded in chat). The requester can't approve their own request.

## 5. Joiner procedure

**SLA:** access ready by start date when the ticket is approved 2+ business days ahead; otherwise within 1 business day of approval.

1. Verify the ticket has all required fields and approvals. If anything is missing, set the ticket to *Pending - Requester* and stop.
2. Check the user doesn't already exist (Identity Center > Users > search by email and employee name). If an old account exists for a rehire, re-enable it and follow the Mover procedure instead.
3. Create the user and add group membership. Use **one** method:

   **Terraform (preferred, keeps code as source of truth)**
   1. Branch the repo, add the user to `var.users` in `terraform/02-identity-center/variables.tf` (or the environment's tfvars) with the approved `groups`.
   2. `terraform plan`. Confirm the plan shows only: 1 user added, N group memberships added. Nothing destroyed.
   3. Paste the plan summary into the ticket, get peer review, then `terraform apply`.

   **Console (only if Terraform is unavailable; reconcile into code within 1 business day)**
   1. IAM Identity Center > Users > **Add user**.
   2. Username, email, first/last name, display name. Password: **Send an email to this user with password setup instructions.**
   3. Add user to the approved group(s). Do not assign the user to an account directly.
   4. Note in the ticket: *Console change, Terraform reconcile pending*.

4. **MFA enrollment.** Identity Center is set to require MFA registration at first sign-in. Tell the user (in the ticket and the welcome email) that they will:
   1. Open the invitation email and set a password (the link expires in 7 days).
   2. Sign in to the AWS access portal and register an MFA device: an authenticator app, or a security key / built-in authenticator. CloudAdmins must register a security key.
5. **Verification** (after the user signs in, or with the user on a call):
   - Identity Center > Users > user > **MFA devices** shows at least one device.
   - Access portal shows only the expected account and role (e.g. `HelpDesk`).
   - For HelpDesk: user can open EC2 > Instances; a test like `aws ec2 terminate-instances --instance-ids i-0123456789abcdef0 --dry-run` returns `UnauthorizedOperation`.
   - For SecurityAnalysts: `aws cloudtrail lookup-events --max-results 5` works; `aws cloudtrail stop-logging --name <trail>` returns `AccessDenied`.
   - For ReadOnlyAuditors: objects under the approved evidence prefix can be read; anything else in the bucket can't.
6. **Evidence to attach to the ticket:** user detail screenshot (groups + MFA device, no secrets), `terraform plan` summary or console audit note, the user's confirmation of sign-in.
7. Resolve the ticket. Resolution note: *User created, groups X, MFA verified, evidence attached.*

## 6. Mover procedure

**SLA:** within 1 business day of the effective date. **Old access must be removed in the same change** as new access is added, unless the ticket documents an approved overlap period (max 14 days) with an end date.

1. Verify ticket fields and approvals from the **new** manager (and Cloud Platform Owner for CloudAdmins).
2. List the user's current groups (Identity Center > Users > user > Groups). Record them in the ticket as *Before*.
3. Compare current groups to the new role. Every group the new role doesn't need is removed.
4. Make the change:
   - **Terraform:** edit the user's `groups` list (remove old, add new). `terraform plan` must show membership removals and additions only. Peer review, apply.
   - **Console:** Groups > old group > remove user; new group > add user. Reconcile into Terraform within 1 business day.
5. **Temporary elevation** (e.g. on-call admin): add to the group with an end date in the ticket and create a follow-up task on that date to remove it. No open-ended temporary access.
6. **Return from leave:** re-enable the user (Users > user > Enable user access), confirm groups still match the current role, confirm the MFA device still works.
7. **Verification:** user's groups match *After* in the ticket. Existing sessions keep old permissions until they expire (max 4h). For an urgent downgrade from CloudAdmins or SecurityAnalysts, also revoke active sessions (section 7, step 4).
8. **Evidence:** *Before* and *After* group lists, plan output or console audit note.

## 7. Leaver procedure

**SLA:**
- Voluntary leaver: access disabled **by end of the last working day**, and in all cases **within 24 hours**.
- Involuntary / for-cause: disabled **within 1 hour** of the HR or Security request, ideally during the termination meeting.

1. Confirm the request comes from HR or Security (or is backed by an HR notice). Managers alone can't trigger an involuntary termination.
2. **Disable first** (fast and reversible): Identity Center > Users > user > **Disable user access**. This blocks new sign-ins immediately.
3. **Remove group memberships** (Terraform: delete the user's entry, or set `groups = []` until deletion; Console: remove from each group). Record the *Before* group list in the ticket.
4. **End active sessions** if the user was in CloudAdmins or SecurityAnalysts, or the departure is involuntary: active portal sessions keep working until they expire. Revoke them (Identity Center > Users > user > **Active sessions** > delete sessions) and, for CloudAdmins, ask the Cloud Platform Owner to check CloudTrail for activity after the disable time.
5. **Remove MFA devices** (Users > user > MFA devices > delete) so the device can't be reused if the account is re-enabled by mistake.
6. **Delete the user** after 30 days (retention period for investigations), via Terraform (remove from `var.users`) or console. Rehires within 30 days are re-enabled instead.
7. **Verification:** user status shows *Disabled*; no group memberships; a sign-in attempt fails. CloudTrail shows `DisableUser` / `DeleteGroupMembership` events with the time.
8. **Evidence:** screenshot of disabled status and empty groups, CloudTrail event time (proves the SLA), ticket timestamps.

## 8. MFA support (common service desk calls)

| Situation | Action |
|---|---|
| Lost or replaced phone / security key | **Verify identity first** (callback to the number in the HR system, or manager confirmation in the ticket; never just caller ID or chat). Then Users > user > MFA devices > delete the old device. User registers a new device at next sign-in. Note the verification method in the ticket. |
| User never got the invitation email | Check spam/quarantine. Users > user > **Send email verification link** / reset password to resend. Never set or read out a password for the user. |
| Forgot password | User selects *Forgot password* on the portal sign-in page. If that fails, service desk sends a reset email from the user page. |
| "I can't see the account / role" | Check group memberships against the ticketed access. If the user needs more, it is a Mover request with approval, not a quick fix. |
| Admin asks to skip MFA "just for today" | Decline. MFA is required by policy (IA-2(1)). Escalate to the Cloud Platform Owner if needed. |

## 9. SLA summary

| Request | Target |
|---|---|
| Joiner | Ready on start date (2+ business days notice) / 1 business day after approval |
| Mover | 1 business day after effective date; old access removed in same change |
| Voluntary leaver | Disabled by end of last day, max 24 hours |
| Involuntary leaver | Disabled within 1 hour |
| Lost MFA device | 4 business hours after identity is verified |
| Access review Revoke | 5 business days after the review decision |

## 10. Evidence retention

Keep tickets, approvals, plan outputs and screenshots for at least one year (or per company policy).
Quarterly access review workbooks reference ticket numbers, so the ticket must stay retrievable.

## 11. Escalation

- Missing approver after 2 business days: escalate to the requester's manager.
- Suspected unauthorized access, or a leaver's account shows activity after their last day: open a Security incident (P1), don't just close the ticket.
- Console change found that doesn't match Terraform (drift): log a finding for the next access review and open a change to reconcile.
