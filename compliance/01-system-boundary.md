
1. **System name and purpose.**  "This is a B3 AWS IAM Identity Lab, which shows least-privilege access for my practice company called Optiprim3 using IAM Identity Center and Terraform."
2. **What's inside the boundary.** 
+-----------------------------------------------------------------------+
┌────────────────────────────────────────────────────────────────────────┐
│ [Diagram Type] System Name [Status: DRAFT / APPROVED]                  │
│ Date: 2026-11-08 | Version: v2.1 | Author: GRC Analyst Lamont          │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│                       SYSTEM BOUNDARY SCOPE                            │
│                                                                        │
│       ┌───────────────┐              ┌───────────────┐                 │
│       │               │              │               │                 │
│       │   Internal    │   ───────►   │   External    │                 │
│       │  Subsystem A  │              │  Subsystem B  │                 │
│       │               │              │               │                 │
│       └───────────────┘              └───────────────┘                 │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘

|  CORPORATE NETWORK (OUT OF SCOPE)                                     |
|  [ EC2 ] [ Networking ] [ real company/driver data ]  [ Telematics ]  |
+-----------------------------------------------------------------------+
                                                              
                           
                                                              
===========================[ SYSTEM BOUNDARY ]===========================

|  AWS TARGET COMPLIANCE ENVIRONMENT (IN-SCOPE)                         |
|                                                                       |
|   [ Identity Center ]       ***Built***                               |
|     └── Individual Accountability and Automated Provisioning          |
|  [ MFA sign-in ]           ***Built***                                |
|     └── Least Privilege (Owner/Admin > Optiprim3 Staff)               |
|  [ The users and groups ]  ***Built***                                |
|     └── Optiprim3 Staff (Help-desk and security-analyst test users)   |
|                                                                       |
|  [ The Permission Sets ]   ***Built***                                |
|     └── Custom inline, AWS managed, optional inline,& evidence policy |
|                                                                       |
|  [ The Terraform Code ]    ***Built***                                |
|     └── For Event History Only (01-billing-alarm, 02-identity-center) |
|                                                                       |
|  [ Billing Alarm ]         ***Built***                                |
|     └── CloudWatch Billing alerts (Free Tier usage Alerts).           |
|     └── Budget (Zero spend budget or Monthly cost budget = $5)        |
|    [ CloudTrail ]    ***Partial***                                    |
|     └── For Event History Only (Event History only; no trail found in |
|us-east-1. Other regions not yet checked.) -->                         |
=========================================================================
        ^
        | (HTTPS / Encrypted Transit)
+-------|---------------------------------------------------------------+

|  EXTERNAL INTERCONNECTIONS    ***Not Built***                         |
|  [ In-Cabin ELD / GPS Hardware in Trucks ] -> [ Telematics Provider API ]
+-----------------------------------------------------------------------+



3. **What's outside it.** Real company and driver data, ELD/telematics systems, EC2 instances, and networking infrastructure are outside this lab’s scope. The lab uses test identities only. The telematics connection shown in the diagram is conceptual and has not been built.
4. **Data and users.** Test identities only, with no real customer data





