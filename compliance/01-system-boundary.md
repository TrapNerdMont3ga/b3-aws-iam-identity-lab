
1. **System name and purpose.**  "This is a B3 AWS IAM Identity Lab, which shows least-privilege access for a OptiPrim3, my practice company called Optiprim3 using IAM Identity Center and Terraform."
2. **What's inside the boundary.** 
+-----------------------------------------------------------------------+

|  CORPORATE NETWORK (OUT OF SCOPE)                                     |
|  [ Terraform Code ]    [ Management Plane ]                                |
+-----------------------------------------------------------------------+
                                                              
                           [ Identity Center ]
                                                              
===========================[ SYSTEM BOUNDARY ]===========================

|  AWS TARGET COMPLIANCE ENVIRONMENT (IN-SCOPE)                         |
|                                                                       |
|  [ MFA sign-in ]           ***Built***                                |
|     └── Owner of company (Owner-operator & CGRC Analyst)              | u                                                                       |
|  [ The users and groups ]  ***Built***                                |
|     └── Optiprim3 Staff (Help-desk and security-analyst test users)   |
|                                                                       |
|  [ The Permission Sets ]   ***Built***                                |
|     └── Custom inline, AWS managed, optional inline,& evidence policy |
|                                                                       |
|  [ The Terraform Code ]    ***Built***                                |
|     └── For CloudAdmins (01-billing-alarm, 02-identity-center ) -->   |
|                                                                       |
|  [ Billing Alarm ]         ***Built***                                |
|     └── CloudWatch Billing alerts (Free Tier usage Alerts)

|     └── Budget (Zero spend budget or Monthly cost budget = $5)        |
=========================================================================
        ^
        | (HTTPS / Encrypted Transit)
+-------|---------------------------------------------------------------+

|  EXTERNAL INTERCONNECTIONS    ***Not Built***                                |
|  [ In-Cabin ELD / GPS Hardware in Trucks ] -> [ Telematics Provider API ]
+-----------------------------------------------------------------------+



3. **What's outside it.** What is outside of it right now is company data and artifacts. 
4. **Data and users.** As of right now I am the only person who signs in. The notes below are for me to edit as I add things. 





