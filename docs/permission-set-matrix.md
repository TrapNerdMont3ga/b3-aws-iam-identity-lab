# Permission Set Matrix: OptiPrim3 Load-Documentation App Account

> OptiPrim3 is a fictional logistics company. Personas are fictional users at example.com.
> Source of truth: `terraform/02-identity-center/permission_sets.tf` and `variables.tf`.
> MFA is enforced for **every** sign-in at the Identity Center level, so every session below is MFA-backed.

| Persona (example user) | Group | Permission set | Session | Key allows | Key denies (explicit `Deny` unless noted) | Approver | Justification |
|---|---|---|---|---|---|---|---|
| Service desk analyst (`jdoe.helpdesk`, `tnguyen.helpdesk`) | HelpDesk | **HelpDesk** (custom inline) | 4h | `ec2:Describe*`, console output/screenshot; ELB, Auto Scaling, CloudWatch read; `iam:Get*`/`List*`, credential report; Access Analyzer read; Health/Support describe | Terminate/stop/delete EC2, security group changes, all IAM writes (create/delete/update/attach/put, MFA device changes, `PassRole`), `sso:*`, `sso-directory:*`, Identity Store writes, `organizations:*` | User's manager | Answer "is the app server up?" and "what access does this person have?" tickets without being able to change anything. |
| Cloud administrator (`asmith.admin`) | CloudAdmins (max 2 members, enforced in Terraform) | **AdministratorAccess** (AWS managed) | **1h** | Everything | None in the permission set. Controls: small group, 1h sessions, security-key MFA, CloudTrail logging, quarterly review | Manager **and** Cloud Platform Owner | Operate and recover the load-documentation app account. Short sessions limit the damage from a stolen session. |
| Security analyst (`jgarcia.secanalyst`) | SecurityAnalysts | **SecurityAnalyst** (custom inline) | 4h | CloudTrail `LookupEvents` and trail/selector read; CloudWatch Logs read + Logs Insights queries; GuardDuty, Security Hub, Config, IAM Access Analyzer `Get*`/`List*`/`Describe*`/`BatchGet*` | Stop/delete/update CloudTrail; delete/put/create in CloudWatch Logs; create/delete/update/archive in GuardDuty; update/disable/delete Security Hub (incl. finding updates); delete/put/start/stop in Config; Access Analyzer writes; `iam:*`, `sso:*`, Identity Store, Organizations | Manager **and** Security Lead | Investigate alerts and suspicious sign-ins. Can't switch off or edit the tooling they watch, which keeps the evidence trustworthy. |
| Compliance auditor (`mlee.auditor`) | ReadOnlyAuditors | **ViewOnlyAccess** (AWS managed) + optional inline evidence policy | 2h | Resource metadata list/describe; if `evidence_bucket_name` is set: `s3:ListBucket` limited to `approved-evidence/*`, `s3:GetObject`/`GetObjectVersion` on that prefix only | No data reads outside the approved prefix (implicit). Explicit `Deny` on S3 put/delete/bucket-config changes for the evidence bucket | Compliance Manager | Check configuration and read evidence that has been approved for audit, without access to customer load documents. |
| Load-docs developer (`rpatel.dev`, `kbrown.dev`) | Developers | **ReadOnlyAccess** (AWS managed) | 4h | Read on resources and data in the app account | All writes (implicit: nothing granted) | User's manager | Debug the app with production read access. Deployments go through the pipeline, not personal sessions. |

## Separation-of-duties rules (enforced in Terraform `variable "users"` validation)

| Rule | Why |
|---|---|
| CloudAdmins ∩ ReadOnlyAuditors = ∅ | Admins can't audit their own work. |
| CloudAdmins ∩ SecurityAnalysts = ∅ | Admins can't monitor themselves for misuse. |
| CloudAdmins size ≤ `max_admins` (default 2) | Keeps privileged access to a small, reviewable group (AC-6(5)). |

## Tests that back this matrix (`terraform test`, offline)

- SecurityAnalyst allow statements contain only read verbs; required tamper denies are present.
- HelpDesk denies terminate, IAM create/delete, and `sso:*`.
- Auditor evidence access is created only when a bucket is configured and is scoped to the approved prefix.
- Session durations match this table.
- SoD and admin-group-size violations fail the plan.
