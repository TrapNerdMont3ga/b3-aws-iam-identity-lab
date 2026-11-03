
1. **System name and purpose.** Write one or two sentences, for example: "This is a B3 AWS IAM Identity Lab, which shows least-privilege access for a my trucking company called Optiprim3 using IAM Identity Center and Terraform."
2. **What's inside the boundary.** 
+-----------------------------------------------------------------------+

|  CORPORATE NETWORK (OUT OF SCOPE)                                     |
|  [ Terraform Code ]    [ GitHub Repo ]                                |
+-----------------------------------------------------------------------+
        |                                                       
        | (Identity Center)
        v                                                       
===========================[ SYSTEM BOUNDARY ]===========================

|  AWS TARGET COMPLIANCE ENVIRONMENT (IN-SCOPE)                         |
|                                                                       |
|  [ The users and groups ]                                             |
|     └── Optiprim3 Staff (Help-desk and security-analyst test users)   |
|                                                                       |
|  [ The Permission Sets ]                                              |
|     └── Custom inline, AWS managed, optional inline,& evidence policy)|
|                                                                       |
|  [ The Terraform Code ]                                               |
|     └── For CloudAdmins (01-billing-alarm, 02-identity-center )       |
|                                                                       |
|  [ Billing Alarm ]                                                    |
|     └── CloudWatch Billing alerts (Free Tier usage Alerts)

|     └── Budget (Zero spend budget or Monthly cost budget = $5)        |
=========================================================================
        ^
        | (HTTPS / Encrypted Transit)
+-------|---------------------------------------------------------------+

|  EXTERNAL INTERCONNECTIONS                                            |
|  [ In-Cabin ELD / GPS Hardware in Trucks ] -> [ Telematics Provider API ]
+-----------------------------------------------------------------------+
List only what you actually built: Identity Center, the users and 


3. **What's outside it.** What is outside of it right now is company data and artifacts. 
4. **Data and users.** As of right now I am the only person who signs in. The notes below are for me to edit as I add things. 

Note who signs in and what data is involved. For B3 that's test identities only, with no real customer data.

Open the AWS console to look only, and don't change anything. Check that every item you mark Built really exists. Paste me your draft when you're done and I'll review it before we move to control selection.

