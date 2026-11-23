# B3 IAM Identity Lab — CloudTrail trail design (POAM-01)

- **Date:** 2026-11-23
- **Status:** Design drafted, awaiting owner approval to apply. No trail has been created.
- **Related:** [poam.md](poam.md) (POAM-01), [control-matrix.md](control-matrix.md), Terraform in `terraform/03-cloudtrail/`.

This is a design and a gated Terraform module. It is **not** implemented in the account. Nothing in this document should be read as evidence that a trail exists.

## Purpose

Close the logging gap described in POAM-01: the lab currently has CloudTrail Event History only (about 90 days of management events, no customer-managed bucket, no confirmed multi-Region coverage). A trail would deliver a durable, owner-controlled copy of management events to S3.

## Decision: one multi-Region management-events trail

| Choice | Decision | Why |
|---|---|---|
| Trails | One trail | The first copy of management events in each Region is delivered without a CloudTrail fee. A second trail that logs the same events is a paid copy. |
| Scope | Multi-Region (default), with global service events included | AWS recommends a multi-Region trail so activity in every enabled Region is captured. Identity and IAM events are global and need `include_global_service_events`. A single-Region trail is possible by setting `is_multi_region_trail = false`, but it would leave other Regions unlogged. |
| Event types | Management events only (read and write) | Meets AU-2 / AU-12 for this lab. No data events (S3 object or Lambda data events are never free). No network-activity events. |
| CloudTrail Lake | Off | Lake is a paid query store. Not in scope. |
| Insights | Off | Insights is a paid extra. Not in scope. |
| CloudWatch Logs | Off by default (`enable_cloudwatch_logs = false`) | Optional later. Ingestion and storage are billed; leave off until the owner accepts that cost. |
| Encryption | SSE-S3 (AES-256) | Avoids a customer-managed KMS key, which can generate a large volume of KMS management events. |
| Retention | S3 lifecycle expiration at 90 days | Keeps retained volume small so storage stays inexpensive. Event History remains available alongside the trail. This is a lab retention choice, not a long-term archive. |
| Apply gate | `enable_cloudtrail = false` by default | `terraform apply` in this module creates no resources until the owner approves a plan with the flag set to true. |

## Architecture

- **Trail:** `b3-iam-lab-management-events` (name is configurable), home Region `us-east-1` by default, multi-Region, log-file validation on, logging enabled.
- **Destination:** a new private S3 bucket (name supplied at apply time; it must be globally unique).
- **Bucket controls:** all four Block Public Access settings on; SSE-S3 default encryption; object ownership BucketOwnerEnforced; a bucket policy that allows only `cloudtrail.amazonaws.com` to `s3:GetBucketAcl` on the bucket and `s3:PutObject` under `AWSLogs/<account-id>/*`, both constrained by `aws:SourceArn` equal to this trail's ARN, plus `s3:x-amz-acl = bucket-owner-full-control` on PutObject (per the [AWS CloudTrail bucket-policy documentation](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/create-s3-bucket-policy-for-cloudtrail.html)).
- **Lifecycle:** expire objects after 90 days; abort incomplete multipart uploads after 7 days.
- **Not included:** data events, Insights, Lake, organization trail, SSE-KMS, public access, a second trail.

The Terraform lives in `terraform/03-cloudtrail/`, as a third module next to `01-billing-alarm` and `02-identity-center`, so it can be applied on its own after approval. The default variable `enable_cloudtrail = false` is the apply gate.

## Cost estimate

**This is an estimate, not a quote or a commitment.** Rates change. Confirm current prices on the linked pages before apply. Retrieved 2026-11-23.

Sources:

- [AWS CloudTrail pricing](https://aws.amazon.com/cloudtrail/pricing/)
- [Managing CloudTrail trail costs](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-trail-manage-costs.html)
- [Amazon S3 pricing](https://aws.amazon.com/s3/pricing/)

| Component | Estimate for this lab (management events only, one trail, 90-day expiry, CloudWatch Logs off) |
|---|---|
| CloudTrail delivery of the first copy of management events to S3 | **$0.** AWS states that one copy of ongoing management events can be delivered to an S3 bucket at no CloudTrail charge (limits may apply). Additional copies, and all data or network-activity events, are paid. |
| Amazon S3 Standard storage, requests, and data transfer | **Typically well under $0.10 per month, often close to $0.00–$0.02**, if retained volume stays well under 1 GB. S3 Standard in US East (N. Virginia) is commonly listed around $0.023 per GB-month for the first 50 TB; confirm the current rate on the S3 pricing page. PUT/LIST request charges at lab volume are usually a few cents or less. This account may not qualify for new-customer S3 Free Tier credits; the 90-day expiry is what keeps the bill small, not an assumption that storage is free. |
| CloudWatch Logs | **$0** while left off. If enabled later, ingestion and storage are billed; do not turn this on without a separate cost decision. |
| CloudTrail Lake / Insights / data events | **$0** while left off. Enabling any of these would change the estimate and needs a new approval. |

**What would make this estimate wrong:** a second trail logging the same management events; enabling data events; enabling Insights or Lake; enabling CloudWatch Logs; a large jump in API volume (for example, SSE-KMS on a busy bucket); a misconfigured trail that retries deliveries (AWS notes retried deliveries after a misconfiguration can be billed).

**Practical reading:** for this lab's current footprint (Identity Center, a billing alarm, and occasional console or CLI work), the likely ongoing cost of the designed trail is a few cents a month or less, dominated by S3, with $0 CloudTrail delivery if it remains the only management-events trail. The owner still needs to approve apply because S3 is not guaranteed to be $0.

## Control mapping (NIST SP 800-53 Rev. 5)

| Control | How this design addresses it | Effect on the current control matrix after apply + evidence |
|---|---|---|
| **AU-2** Event Logging | The trail is configured to log all management events (read and write) in enabled Regions, including global IAM events. Event types that are out of scope (data events, Insights) are documented as not selected. | **Would move from Partial to Implemented** once the trail is applied and evidence is captured. |
| **AU-3** Content of Audit Records | CloudTrail management events record the principal, time, Region, source IP, event name, and result. Not a current matrix row. | No status change (not in the matrix). Could be added later as Implemented if the owner wants that row, with a sample event as evidence. |
| **AU-6** Audit Review, Analysis, and Reporting | The trail gives SecurityAnalyst / ReadOnlyAuditor roles a durable source to review. A review *procedure* (who looks, how often) is not created by Terraform. Not a current matrix row. | No status change. Would stay a process gap until a review cadence is written and followed. |
| **AU-9** Protection of Audit Information | Private bucket, Block Public Access, SSE-S3, bucket policy limited to CloudTrail and `aws:SourceArn`, log-file validation. Not a current matrix row. | No status change (not in the matrix). Could be added later as Implemented with redacted bucket-policy and validation evidence. |
| **AU-11** Audit Record Retention | Lifecycle expiration at 90 days is an explicit retention setting (lab-scale, not long-term archive). Event History remains ~90 days as well. Not a current matrix row. | No status change (not in the matrix). A 90-day policy could be listed as Implemented for this lab if added; it would not satisfy a longer statutory retention requirement. |
| **AU-12** Audit Record Generation | The trail generates management-event records and delivers them to the owner-controlled bucket with logging enabled. | **Would move from Partial to Implemented** once the trail is applied and evidence is captured. |

Until apply, AU-2 and AU-12 stay **Partial**. This design is not evidence of implementation.

## Apply and verify (only after owner approval)

Do not run `terraform apply` until the owner has reviewed this design and a plan.

1. In a local, git-ignored `terraform/03-cloudtrail/terraform.tfvars` (copy from `terraform.tfvars.example`), set `enable_cloudtrail = true` and a globally unique `trail_bucket_name`. Leave `enable_cloudwatch_logs = false` unless a separate cost decision is recorded.
2. From `terraform/03-cloudtrail/`, run `terraform init` and `terraform plan`. Review the plan: it should create one bucket and its controls, one trail, and no data-event or Insights resources. Do not apply if the plan shows unexpected resources.
3. After the owner approves the plan, run `terraform apply`.
4. Verify, then capture redacted evidence (next section):
   - Trail exists, logging is on, multi-Region (if that was the plan), log-file validation is on, management events only.
   - Bucket: Block Public Access is on, default encryption is AES256 / SSE-S3, lifecycle expires objects at 90 days, bucket policy includes `cloudtrail.amazonaws.com` and `aws:SourceArn`.
   - After a harmless management action (for example, `sts:GetCallerIdentity` or a console page load), confirm a new log object appears under `AWSLogs/` or that `LookupEvents` still shows the event (Event History continues to work).
5. Do not enable data events, Insights, Lake, a second trail, or CloudWatch Logs without a new design note and cost decision.

## Evidence to capture after apply (redact before commit)

Redact 12-digit account IDs, ARNs that embed an account ID, bucket names if they embed an account ID, and any email addresses. Do not rewrite git history to clean a leaked ID — redact in a follow-up commit, as with earlier evidence.

Suggested filenames (not yet captured):

| File | Shows |
|---|---|
| `screenshots/poam-01-cloudtrail-trail-settings.png` | Trail name, multi-Region, log-file validation, logging on, management events only (no data events). |
| `screenshots/poam-01-cloudtrail-bucket-access-encryption.png` | Block Public Access and SSE-S3 (AES256) on the log bucket. |
| `screenshots/poam-01-cloudtrail-bucket-policy.png` | Bucket policy with `cloudtrail.amazonaws.com` and `aws:SourceArn` (ARN and account ID redacted). |
| `screenshots/poam-01-cloudtrail-lifecycle-90d.png` | Lifecycle rule expiring logs at 90 days. |
| `screenshots/poam-01-cloudtrail-sample-delivery.png` | A sample delivered log prefix or a LookupEvents result after a test action. |

Optional CLI (redact IDs): `aws cloudtrail describe-trails`, `get-trail-status`, `get-event-selectors`, plus `aws s3api get-bucket-policy`, `get-bucket-encryption`, `get-public-access-block`, and `get-bucket-lifecycle-configuration`.

After those files exist, update [control-matrix.md](control-matrix.md) (AU-2 and AU-12 to Implemented) and close or update POAM-01. Do not make those status changes on the strength of this design alone.

## What this design does not do

- It does not create the trail until the owner approves and someone applies the module with `enable_cloudtrail = true`.
- It does not cap AWS spend (the $5 budget still only alerts).
- It does not add a formal audit-review procedure (AU-6).
- It does not provide long-term archival beyond 90 days (AU-11 at lab scale only).
- It does not log data-plane events on S3 objects or similar.
