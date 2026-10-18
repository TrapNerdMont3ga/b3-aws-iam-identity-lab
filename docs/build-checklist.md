# Build checklist: OptiPrim3 identity lab (to perform once AWS access exists)

Work top to bottom. Each **[SS ##]** is a screenshot to save in `screenshots/` with the file name from
the README. Redact the account ID, emails, and the access portal URL before committing.

**Needs from Lamont before starting:** an AWS account he owns (new account recommended), the root
login + root MFA device, an email address for billing alerts, and approval that the lab stays at $0.
Nothing in this lab is expected to cost money.

## 0. Account hygiene and cost guardrail (console, as root, done once)

- [ ] Sign in as root. Account menu > **Security credentials** > Assign MFA device (authenticator app or security key). **[SS 01]**
- [ ] Confirm no root access keys exist (same page). Delete any that do.
- [ ] Billing and Cost Management > **Billing preferences** > Alert preferences > enable **Receive CloudWatch billing alerts** (and Free Tier usage alerts). **[SS 02]**
- [ ] Billing and Cost Management > **Budgets** > Create budget > *Zero spend budget* or *Monthly cost budget* = $5 with your email. **[SS 03]**

## 1. Enable IAM Identity Center (console, as root)

- [ ] Pick one region and keep it (e.g. `us-east-1`). Open **IAM Identity Center** > **Enable** > *Enable with AWS Organizations* (organization instance). This creates the organization; the account becomes the management account.
- [ ] Settings > note the **Identity source** = Identity Center directory, the region, and the **AWS access portal URL**. **[SS 06]**
- [ ] Optional: Settings > customize the access portal URL subdomain.

## 2. Enforce MFA (console)

- [ ] Identity Center > **Settings** > **Authentication** tab > Multi-factor authentication > **Configure**:
  - Prompt users for MFA: **Every time they sign in (always-on context)**
  - Users can authenticate with: **Security keys and built-in authenticators** and **Authenticator apps**
  - If a user does not yet have a registered MFA device: **Require them to register an MFA device at sign in**
- [ ] Save. **[SS 07]**

## 3. Bootstrap admin for Terraform (console, then CLI)

This avoids creating IAM access keys. It is the only manual identity and is removed at teardown.

- [ ] Identity Center > Permission sets > Create > Predefined > AdministratorAccess, name it **`LabBootstrapAdmin`**, session 1 hour.
- [ ] Users > Add user `lamont.bootstrap` (Lamont's real email). Accept the invite, set password, register MFA.
- [ ] AWS accounts > select the account > Assign users or groups > `lamont.bootstrap` > `LabBootstrapAdmin`.
- [ ] Sign out of root. From now on, use the access portal.
- [ ] On the workstation:
  ```bash
  aws configure sso            # SSO start URL = access portal URL, region = Identity Center region
                               # choose LabBootstrapAdmin, profile name: b3-lab
  aws sso login --profile b3-lab
  export AWS_PROFILE=b3-lab
  aws sts get-caller-identity  # confirm the AWSReservedSSO_LabBootstrapAdmin role
  aws sso-admin list-instances # confirm InstanceArn and IdentityStoreId
  ```

## 4. Deploy the billing alarm (Terraform, first)

```bash
cd terraform/01-billing-alarm
cp terraform.tfvars.example terraform.tfvars   # set alert_email (git-ignored)
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

- [ ] Confirm the SNS subscription from the email ("AWS Notification - Subscription Confirmation"). **[SS 05]**
- [ ] CloudWatch (us-east-1) > Alarms > billing alarm visible, state OK or Insufficient data (normal for the first hours). **[SS 04]**

## 5. Deploy Identity Center resources (Terraform)

```bash
cd ../02-identity-center
cp terraform.tfvars.example terraform.tfvars   # set target_account_id, identity_center_region, email_domain
                                                # optional: evidence_bucket_name (see 5a)
terraform init
terraform test                                  # offline tests, should be 10 passed
terraform plan -out tfplan                      # expect: 5 groups, 7 users, 7 memberships,
                                                # 5 permission sets, 3 managed policy attachments,
                                                # 2 inline policies (+1 if evidence bucket set),
                                                # 5 account assignments, 1 admin-size guard
terraform apply tfplan
```

- [ ] Screenshot the plan summary. **[SS 08]**

### 5a. Optional: approved evidence bucket for auditors

- [ ] S3 > Create bucket (e.g. `optiprim3-compliance-evidence-<random>`), Block Public Access on, default encryption on.
- [ ] Upload a sample file to `approved-evidence/` (e.g. the redacted review workbook) and another file outside that prefix (e.g. `drafts/`).
- [ ] Set `evidence_bucket_name` in `terraform.tfvars`, then `terraform apply` again (adds 1 inline policy to ViewOnlyAccess).
- [ ] Console: Groups list with member counts **[SS 09]**; Permission sets with session durations **[SS 10]**; AWS accounts > account > assigned groups and permission sets **[SS 11]**.
- [ ] CLI cross-check (also used as review evidence):
  ```bash
  IDS=$(aws sso-admin list-instances --query 'Instances[0].IdentityStoreId' --output text)
  ARN=$(aws sso-admin list-instances --query 'Instances[0].InstanceArn' --output text)
  aws identitystore list-users  --identity-store-id "$IDS" --query 'Users[].UserName'
  aws identitystore list-groups --identity-store-id "$IDS" --query 'Groups[].DisplayName'
  aws sso-admin list-permission-sets --instance-arn "$ARN"
  aws sso-admin list-account-assignments --instance-arn "$ARN" \
    --account-id <ACCOUNT_ID> --permission-set-arn <PS_ARN>
  ```

Note: Terraform-created users get no invitation email automatically. For each test persona you plan to sign in as, open Users > user > **Send email verification link** / **Reset password** > send email. Emails are built as `<username>@<email_domain>`, so set `email_domain` to a domain you control with a catch-all mailbox, or change the persona's email in the console, so you can receive them.

## 6. Test personas

- [ ] Sign in as `jdoe.helpdesk` in a private browser window: set password, MFA registration prompt appears. **[SS 15]**
- [ ] Access portal shows only the account with the **HelpDesk** role. **[SS 16]**
- [ ] EC2 > Instances and IAM > Users load (view works). **[SS 17]**
- [ ] Denied actions (no instance needed thanks to `--dry-run`; the IAM decision is evaluated first):
  ```bash
  aws configure sso   # profile b3-helpdesk, role HelpDesk
  aws ec2 terminate-instances --instance-ids i-0123456789abcdef0 --dry-run --profile b3-helpdesk
  #   expect: UnauthorizedOperation
  aws iam create-user --user-name should-fail --profile b3-helpdesk
  #   expect: AccessDenied ... with an explicit deny
  ```
  Screenshot both errors. **[SS 18]**
- [ ] Sign in as `jgarcia.secanalyst` (profile `b3-secanalyst`, role SecurityAnalyst):
  ```bash
  aws cloudtrail lookup-events --max-results 5 --profile b3-secanalyst          # expect: events returned
  aws cloudtrail stop-logging --name any-trail --profile b3-secanalyst          # expect: AccessDenied (explicit deny)
  aws logs delete-log-group --log-group-name any --profile b3-secanalyst        # expect: AccessDenied
  ```
  Screenshot the successful lookup and the denials. **[SS 18b]**
- [ ] If the evidence bucket exists, sign in as `mlee.auditor` and run
  `aws s3 cp s3://<bucket>/approved-evidence/<file> - --profile b3-auditor` (works) and
  `aws s3 cp s3://<bucket>/drafts/<file> - --profile b3-auditor` (AccessDenied).
- [ ] Optional: sign in as `asmith.admin` and confirm the session ends after 1 hour.

## 7. Simulate the access review findings

- [ ] **Drift / over-privilege (F-Q4-01):** as bootstrap admin, in the console add `kbrown.dev` to `CloudAdmins`. Run `python3 scripts/check_membership_drift.py`: it should print `DRIFT kbrown.dev: in ['CloudAdmins'] but not in Terraform`. Screenshot. **[SS 14]** Then remove kbrown.dev from CloudAdmins, re-run the script (`no drift`), and screenshot the user's groups. **[SS 13]**
- [ ] **Stale account (F-Q4-02):** Users > `tnguyen.helpdesk` > **Disable user access**. **[SS 12]**
- [ ] CloudTrail > Event history, filter Event source `sso-directory.amazonaws.com` / `identitystore.amazonaws.com` and `signin.amazonaws.com`: show the AddMemberToGroup / DisableUser and sign-in events. **[SS 19]**
- [ ] Last-sign-in evidence (closes F-Q4-03), run as SecurityAnalyst:
  ```bash
  aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=Authenticate \
    --start-time 2026-07-01 --query 'Events[].[EventTime,Username]' --output table --profile b3-secanalyst
  ```
  (Identity Center portal sign-ins are logged with event source `signin.amazonaws.com` / `sso.amazonaws.com`; adjust the event name to what appears in Event history.)
- [ ] Update `evidence/access-review-Q4-2026.xlsx` and `docs/findings-and-remediation.md` with real (redacted) data, or keep the example data and note which rows were reproduced in the lab.

Note on drift: Terraform only tracks memberships it created, so a console-added membership does not show in `terraform plan`. That is why the drift script exists, and it's a good talking point for interviews.

## 8. Teardown

```bash
cd terraform/02-identity-center && terraform destroy
```

- [ ] Delete any test EC2 instances (if launched). Check EC2 in every region used.
- [ ] Disable GuardDuty / Security Hub / Config if you enabled them for testing; empty and delete the evidence bucket if created.
- [ ] Remove `lamont.bootstrap` / `LabBootstrapAdmin` if the account will not be reused (do this last).
- [ ] Keep `01-billing-alarm` (free). Billing > Bills shows $0.00. **[SS 20]**

## 9. Publish

- [ ] `git status`: confirm no `*.tfstate`, `terraform.tfvars`, `.terraform/`, or unredacted screenshots are staged.
- [ ] Optional scan: `git log -p | grep -E '[0-9]{12}|AKIA|aws_secret'` (only the example `111111111111` should appear).
- [ ] Create the public GitHub repo, add the remote, push.
