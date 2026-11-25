# B3 IAM Identity Lab — SOC 2 and ISO/IEC 27001:2022 crosswalk

- **Date:** 2026-11-24
- **Status:** Portfolio mapping only. This is **not** an audit, examination, certification, or attestation, and it does not claim that OptiPrim3 or this lab is SOC 2 or ISO/IEC 27001 compliant.
- **Basis:** The 11 rows in [control-matrix.md](control-matrix.md) (NIST SP 800-53 Rev. 5). Status in that matrix is unchanged by this document.
- **Method:** Each row is mapped by control *intent* to Trust Services Criteria (TSC) and to ISO/IEC 27001:2022 Annex A controls. Mappings are the author's judgment for a portfolio lab, not a licensed or official mapping table.

## How to read this

- **SOC 2** criteria below use the AICPA Trust Services Criteria for Security (the CC series). Common points such as CC6.x (logical access) and CC7.x (system operations / monitoring) appear most often for this lab.
- **ISO/IEC 27001:2022** numbers are Annex A controls (the same numbering as ISO/IEC 27002:2022). Older 2013 numbers (for example A.9.x) are not used.
- A mapping means "this lab control, if implemented as described in the matrix, would support this criterion or Annex A control." It does not mean the criterion is fully satisfied for a production organization.
- Partial and risk-accepted rows are mapped honestly; the gap stays visible.

## Sources

1. AICPA, *2017 Trust Services Criteria for Security, Availability, Processing Integrity, Confidentiality, and Privacy*, including the 2022 revisions to points of focus, [AICPA & CIMA resource page](https://www.aicpa-cima.com/resources/download/2017-trust-services-criteria).
2. ISO/IEC 27001:2022, Annex A (Information security controls), aligned with ISO/IEC 27002:2022.
3. NIST SP 800-53 Rev. 5, *Security and Privacy Controls for Information Systems and Organizations*, [NIST Computer Security Resource Center](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final). The control-matrix implementation statements are the lab-side source.

There is no official AICPA or ISO table that one-for-one certifies 800-53 Rev. 5 rows to TSC or Annex A. Treat the table below as a study aid and interview talking point, not as evidence for an auditor.

## Crosswalk

| Matrix control | Matrix status (2026-11-24) | SOC 2 TSC (Security) | ISO/IEC 27001:2022 Annex A | Notes |
|---|---|---|---|---|
| **AC-2** Account Management | Implemented | CC6.1, CC6.2, CC6.3 | A.5.16 Identity management; A.5.18 Access rights | Unique Identity Center users, group-based provisioning, and a documented JML runbook support registration, issuance, and modification of credentials and rights. |
| **AC-3** Access Enforcement | Implemented | CC6.1, CC6.3 | A.5.15 Access control; A.8.3 Information access restriction | Permission sets enforce allow-lists and explicit denies. Persona tests show out-of-role actions are denied. |
| **AC-6** Least Privilege | Implemented | CC6.3 | A.5.15 Access control; A.8.2 Privileged access rights; A.8.3 Information access restriction | Custom HelpDesk and SecurityAnalyst sets and session-duration limits are the lab's least-privilege implementation. |
| **AC-6(5)** Privileged Accounts | Partial | CC6.1, CC6.2, CC6.3 | A.8.2 Privileged access rights; A.5.18 Access rights | CloudAdmins is capped and admin sessions are short. A standing IAM user with a long-term access key remains; the owner accepted that residual risk (POAM-05). The TSC/ISO mapping is therefore only partial. |
| **IA-2** Identification and Authentication | Implemented | CC6.1 | A.5.16 Identity management; A.8.5 Secure authentication | Workforce users sign in to the Identity Center access portal with unique identities and temporary credentials. |
| **IA-2(1)** MFA | Implemented | CC6.1 | A.5.17 Authentication information; A.8.5 Secure authentication | Identity Center MFA is always-on, and a passkey was assigned to the remaining IAM user for console access. Access keys still bypass MFA; that residual is recorded under AC-6(5) / POAM-05, not as an IA-2(1) gap. |
| **AU-2** Event Logging | Implemented | CC7.2 | A.8.15 Logging | A multi-Region management-events trail delivers logs to a private SSE-S3 bucket with log-file validation and 90-day retention (POAM-01 closed 2026-11-24). Event History remains as a console store. |
| **AU-12** Audit Record Generation | Implemented | CC7.2 | A.8.15 Logging; A.8.16 Monitoring activities | The applied trail generates and delivers management-event records to the owner-controlled bucket. Delivery and log-file validation are evidenced (POAM-01 closed 2026-11-24). |
| **CM-2** Baseline Configuration | Implemented | CC8.1 | A.8.9 Configuration management | Billing-alarm and Identity Center configuration are defined in version-controlled Terraform, with provider versions pinned. |
| **Cost guardrail** (no direct 800-53 control) | Partial | No direct TSC. Closest operational neighbor is monitoring under CC7.1 / CC7.2, not a cost-cap criterion. | No direct Annex A control. Closest neighbors are operational monitoring (A.8.16) and, loosely, use of resources in A.5.23 / supplier or cloud use — not a spend cap. | The $5 budget and confirmed SNS alert exist; they do not stop spending. This row stays a cost-control practice, not a forced 800-53, SOC 2, or ISO control. |
| **SI-12 / SA-8(33)** Identifier redaction process | Implemented (process) | No single TSC. Supports careful handling of system information in published artifacts; Confidentiality criteria (C1.1 and related) are only loosely adjacent and are not claimed. | A.8.10 Information deletion; A.8.11 Data masking (as an analogue for identifier redaction in public evidence) | This is a publication-hygiene process for the public repo, not a full data-retention or PII-masking program. Git history was not rewritten. |

## What this mapping is not

- It is not a SOC 2 Type I or Type II report, and it is not an ISO/IEC 27001 certification or statement of applicability for a production organization.
- It does not add or remove rows from the NIST control matrix.
- It does not claim that Partial or risk-accepted gaps are closed in SOC 2 or ISO terms.
- Formal SOC 2 examination and ISO certification, if ever required for a real OptiPrim3 business, would have to be performed by appropriately licensed or accredited parties, against a defined production system and evidence period.

## Revision

| Date | Change |
|---|---|
| 2026-11-23 | Initial portfolio crosswalk of the approved 11-row control matrix. |
| 2026-11-24 | AU-2 and AU-12 status updated to Implemented after POAM-01 closure. |
