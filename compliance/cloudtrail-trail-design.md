# B3 IAM Identity Lab — CloudTrail trail design (POAM-01)

- **Date:** 2026-11-23 (design); applied 2026-11-23; evidence captured 2026-11-24
- **Status:** Applied 2026-11-23 by the account owner. Redacted evidence committed 2026-11-24. POAM-01 is closed. AU-2 and AU-12 are Implemented.
- **Related:** [poam.md](poam.md) (POAM-01, closed), [control-matrix.md](control-matrix.md), Terraform in `terraform/03-cloudtrail/`.

This document is the design record and, as of 2026-11-24, the evidence index for the applied trail. The account owner applied the CloudTrail module on 2026-11-23. The Terraform module default remains `enable_cloudtrail = false` so a later apply from a clean checkout does not create a second trail.

## Purpose

Close the logging gap described in POAM-01: the lab previously had CloudTrail Event History only (about 90 days of management events, no customer-managed bucket, no confirmed multi-Region coverage). The applied trail delivers a durable, owner-controlled copy of management events to S3.

## Decision: one multi-Region management-events trail

| Choice | Decision | Why |
|---|---|---|
| Trails | One trail | The first copy of management events in each Region is delivered without a CloudTrail fee. A second trail that logs the same events is a paid copy. |
| Scope | Multi-Region (default), with global service events included | AWS recommends a multi-Region trail so activity in every enabled Region is captured. Identity and IAM events are global and need `include_global_service_events`. A single-Region trail is possible by setting `is_multi_region_trail = false`, but it would leave other Regions unlogged. |
| Event types | Management events only (read and write) | Meets AU-2 / AU-12 for this lab. No data events (S3 object or Lambda data events are never free). No network-activity events. |
| CloudTrail Lake | Off | Lake is a paid query store. Not in scope. |
| Insights | Off | Insights is a paid extra. Not in scope. |
| CloudWatch Logs | Off (`enable_cloudwatch_logs = false`) | Optional later. Ingestion and storage are billed; leave off until the owner accepts that cost. Confirmed off in the applied configuration. |
| SNS notification delivery | Off | Trail SNS notification delivery is Disabled. This is not the billing-alert SNS topic. |
| Encryption | SSE-S3 (Amazon S3 managed keys), not SSE-KMS | Avoids a customer-managed KMS key, which can generate a large volume of KMS management events. Trail "Log file SSE-KMS encryption" is Not enabled. Bucket default encryption is SSE-S3. |
| Retention | S3 lifecycle expiration at 90 days | Keeps retained volume small so storage stays inexpensive. Event History remains available alongside the trail. This is a lab retention choice, not a long-term archive. |
| Apply gate | `enable_cloudtrail = false` by default | `terraform apply` in this module creates no resources until the owner approves a plan with the flag set to true. The live trail was applied under that approval on 2026-11-23. |

## Applied configuration (2026-11-23)

- **Trail:** `b3-iam-lab-management-events`, home Region `us-east-1`, multi-Region: Yes, logging: On, log-file validation: Enabled.
- **Event types:** Management events only; API activity All. No data events, Insights, or Lake.
- **Destination:** private S3 bucket `b3-iam-lab-cloudtrail-logs-optiprim3-2027`.
- **Bucket controls:** Block all public access On; default encryption SSE-S3 (not KMS); bucket policy allows `cloudtrail.amazonaws.com` to `s3:GetBucketAcl` and `s3:PutObject` under `AWSLogs/<account-id>/*`, constrained by `aws:SourceArn` equal to this trail's ARN, plus `s3:x-amz-acl = bucket-owner-full-control` on PutObject (per the [AWS CloudTrail bucket-policy documentation](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/create-s3-bucket-policy-for-cloudtrail.html)). In the published policy screenshot, the account ID is replaced with the placeholder `111122223333`.
- **Lifecycle:** rule `expire-cloudtrail-logs`, Enabled, entire bucket, objects expire at day 90.
- **SNS notification delivery:** Disabled.
- **CloudWatch Logs:** Off.
- **Not included:** data events, Insights, Lake, organization trail, SSE-KMS, public access, a second trail.

The Terraform lives in `terraform/03-cloudtrail/`, as a third module next to `01-billing-alarm` and `02-identity-center`.

## Cost estimate

**This is an estimate, not a quote or a commitment.** Rates change. Confirm current prices on the linked pages before further changes. Retrieved 2026-11-23.

Sources:

- [AWS CloudTrail pricing](https://aws.amazon.com/cloudtrail/pricing/)
- [Managing CloudTrail trail costs](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-trail-manage-costs.html)
- [Amazon S3 pricing](https://aws.amazon.com/s3/pricing/)

| Component | Estimate for this lab (management events only, one trail, 90-day expiry, CloudWatch Logs off, SNS notification delivery off, SSE-S3 not KMS) |
|---|---|
| CloudTrail delivery of the first copy of management events to S3 | **$0.** AWS states that one copy of ongoing management events can be delivered to an S3 bucket at no CloudTrail charge (limits may apply). Additional copies, and all data or network-activity events, are paid. |
| Amazon S3 Standard storage, requests, and data transfer | **Typically well under $0.10 per month, often close to $0.00–$0.02**, if retained volume stays well under 1 GB. S3 Standard in US East (N. Virginia) is commonly listed around $0.023 per GB-month for the first 50 TB; confirm the current rate on the S3 pricing page. PUT/LIST request charges at lab volume are usually a few cents or less. This account may not qualify for new-customer S3 Free Tier credits; the 90-day expiry is what keeps the bill small, not an assumption that storage is free. |
| CloudWatch Logs | **$0** while left off. If enabled later, ingestion and storage are billed; do not turn this on without a separate cost decision. |
| CloudTrail Lake / Insights / data events | **$0** while left off. Enabling any of these would change the estimate and needs a new approval. |

**What would make this estimate wrong:** a second trail logging the same management events; enabling data events; enabling Insights or Lake; enabling CloudWatch Logs; a large jump in API volume (for example, SSE-KMS on a busy bucket); a misconfigured trail that retries deliveries (AWS notes retried deliveries after a misconfiguration can be billed).

**Practical reading:** for this lab's current footprint (Identity Center, a billing alarm, and occasional console or CLI work), the likely ongoing cost of the applied trail is a few cents a month or less, dominated by S3, with $0 CloudTrail delivery if it remains the only management-events trail. S3 is not guaranteed to be $0.

## Control mapping (NIST SP 800-53 Rev. 5)

| Control | How this design addresses it | Effect on the current control matrix after apply + evidence |
|---|---|---|
| **AU-2** Event Logging | The trail logs all management events (read and write) in enabled Regions, including global IAM events. Event types that are out of scope (data events, Insights) are documented as not selected. | **Implemented** as of 2026-11-24 (applied 2026-11-23; evidence below). |
| **AU-3** Content of Audit Records | CloudTrail management events record the principal, time, Region, source IP, event name, and result. Not a current matrix row. | No status change (not in the matrix). Could be added later as Implemented if the owner wants that row, with a sample event as evidence. |
| **AU-6** Audit Review, Analysis, and Reporting | The trail gives SecurityAnalyst / ReadOnlyAuditor roles a durable source to review. A review *procedure* (who looks, how often) is not created by Terraform. Not a current matrix row. | No status change. Would stay a process gap until a review cadence is written and followed. |
| **AU-9** Protection of Audit Information | Private bucket, Block Public Access, SSE-S3, bucket policy limited to CloudTrail and `aws:SourceArn`, log-file validation. Not a current matrix row. | No status change (not in the matrix). Could be added later as Implemented with the redacted bucket-policy and validation evidence already captured. |
| **AU-11** Audit Record Retention | Lifecycle expiration at 90 days is an explicit retention setting (lab-scale, not long-term archive). Event History remains ~90 days as well. Not a current matrix row. | No status change (not in the matrix). A 90-day policy could be listed as Implemented for this lab if added; it would not satisfy a longer statutory retention requirement. |
| **AU-12** Audit Record Generation | The trail generates management-event records and delivers them to the owner-controlled bucket with logging enabled. | **Implemented** as of 2026-11-24 (applied 2026-11-23; evidence below). |

## Evidence (captured 2026-11-24; trail applied 2026-11-23)

Account IDs, the S3 object Owner canonical ID, and the object ETag are redacted in the published screenshots. In the bucket-policy screenshot, the account ID is replaced with the placeholder `111122223333` (caption: account ID replaced with placeholder).

| File | Shows |
|---|---|
| `screenshots/poam-01-cloudtrail-trail-details.png` | Trail `b3-iam-lab-management-events`: logging On, multi-Region Yes, log-file validation Enabled, log file SSE-KMS encryption Not enabled, SNS notification delivery Disabled, organization trail Not enabled. **Log delivery evidence:** Last log file delivered November 24, 2026, 21:05:57 (UTC-05:00). Last file validation delivered November 24, 2026, 21:01:05 (UTC-05:00). The account ID in the trail log location path is redacted. |
| `screenshots/poam-01-cloudtrail-management-events.png` | Management events only: API activity All. KMS and RDS Data API events are not excluded. |
| `screenshots/poam-01-cloudtrail-block-public-access.png` | Log bucket: Block all public access On. |
| `screenshots/poam-01-cloudtrail-default-encryption-sse-s3.png` | Bucket default encryption: SSE-S3 (Amazon S3 managed keys), not SSE-KMS. |
| `screenshots/poam-01-cloudtrail-bucket-policy.png` | Bucket policy with `cloudtrail.amazonaws.com`, `aws:SourceArn`, and `s3:x-amz-acl = bucket-owner-full-control`. Account ID replaced with placeholder. |
| `screenshots/poam-01-cloudtrail-lifecycle-90d.png` | Lifecycle rule `expire-cloudtrail-logs`, Enabled, entire bucket, objects expire at day 90. |
| `screenshots/poam-01-cloudtrail-digest-log-file-validation.png` | A `CloudTrail-Digest` `.json.gz` object dated 2026-11-23. This proves **log file validation**, not log delivery by itself. |

**Delivery and validation:** Treat the trail-details screenshot (last log file delivered November 24, 2026, 21:05:57 (UTC-05:00)) together with the digest-object screenshot as delivery and validation evidence. A digest file is not, on its own, proof that data log objects were delivered. A screenshot of a `CloudTrail/` log object (as opposed to a `CloudTrail-Digest/` object) is optional future evidence and is not required to close POAM-01.

The digest object was taken from the `23/` prefix (2026-11-23). Later date prefixes may contain additional objects; they were not required for this evidence set.

## What this does not do

- It does not cap AWS spend (the $5 budget still only alerts).
- It does not add a formal audit-review procedure (AU-6).
- It does not provide long-term archival beyond 90 days (AU-11 at lab scale only).
- It does not log data-plane events on S3 objects or similar.
- It does not enable CloudWatch Logs or trail SNS notification delivery.
- It does not use SSE-KMS.
