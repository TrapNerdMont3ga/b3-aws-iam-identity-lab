# Policies are written with jsonencode() so their contents are known at plan time and
# can be checked by the offline tests in tests/offline.tftest.hcl.
#
# MFA: Identity Center is configured to require MFA on every sign-in (see
# docs/build-checklist.md). Every session behind these permission sets is therefore MFA-backed.

# ---------- AdministratorAccess (CloudAdmins) ----------
resource "aws_ssoadmin_permission_set" "administrator" {
  name             = "AdministratorAccess"
  description      = "Full admin for a small group. 1h session to limit privileged exposure."
  instance_arn     = local.instance_arn
  session_duration = "PT1H"
}

resource "aws_ssoadmin_managed_policy_attachment" "administrator" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.administrator.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ---------- ReadOnlyAccess (Developers) ----------
resource "aws_ssoadmin_permission_set" "read_only" {
  name             = "ReadOnlyAccess"
  description      = "Read-only access to the load-documentation app account."
  instance_arn     = local.instance_arn
  session_duration = "PT4H"
}

resource "aws_ssoadmin_managed_policy_attachment" "read_only" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.read_only.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ---------- ViewOnlyAccess (ReadOnlyAuditors) ----------
# ViewOnlyAccess lists/describes resource metadata without reading data contents. If an
# evidence bucket is configured, auditors can also read objects under the approved prefix only.
resource "aws_ssoadmin_permission_set" "view_only" {
  name             = "ViewOnlyAccess"
  description      = "Auditor: resource metadata plus read on approved compliance evidence."
  instance_arn     = local.instance_arn
  session_duration = "PT2H"
}

resource "aws_ssoadmin_managed_policy_attachment" "view_only" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.view_only.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
}

locals {
  evidence_enabled = var.evidence_bucket_name != ""

  auditor_evidence_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "ListApprovedEvidencePrefixOnly"
        Effect    = "Allow"
        Action    = ["s3:ListBucket"]
        Resource  = "arn:aws:s3:::${var.evidence_bucket_name}"
        Condition = { StringLike = { "s3:prefix" = ["${var.evidence_prefix}*"] } }
      },
      {
        Sid      = "ReadApprovedEvidenceObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:GetObjectVersion"]
        Resource = "arn:aws:s3:::${var.evidence_bucket_name}/${var.evidence_prefix}*"
      },
      {
        Sid    = "DenyEvidenceWrites"
        Effect = "Deny"
        Action = [
          "s3:PutObject*", "s3:DeleteObject*", "s3:PutBucket*", "s3:DeleteBucket*",
          "s3:PutLifecycleConfiguration", "s3:RestoreObject",
        ]
        Resource = [
          "arn:aws:s3:::${var.evidence_bucket_name}",
          "arn:aws:s3:::${var.evidence_bucket_name}/*",
        ]
      },
    ]
  })
}

resource "aws_ssoadmin_permission_set_inline_policy" "view_only_evidence" {
  count = local.evidence_enabled ? 1 : 0

  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.view_only.arn
  inline_policy      = local.auditor_evidence_policy
}

# ---------- HelpDesk (custom least privilege) ----------
resource "aws_ssoadmin_permission_set" "helpdesk" {
  name             = "HelpDesk"
  description      = "Custom least-privilege: view EC2 and IAM for troubleshooting; no changes."
  instance_arn     = local.instance_arn
  session_duration = "PT4H"
}

locals {
  helpdesk_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ViewEC2ForTroubleshooting"
        Effect = "Allow"
        Action = [
          "ec2:Describe*", "ec2:GetConsoleOutput", "ec2:GetConsoleScreenshot",
          "elasticloadbalancing:Describe*", "autoscaling:Describe*",
          "cloudwatch:Describe*", "cloudwatch:Get*", "cloudwatch:List*",
          "ssm:DescribeInstanceInformation",
        ]
        Resource = "*"
      },
      {
        Sid    = "ViewIAMForAccessQuestions"
        Effect = "Allow"
        Action = [
          "iam:Get*", "iam:List*", "iam:GenerateCredentialReport",
          "iam:GenerateServiceLastAccessedDetails",
          "access-analyzer:List*", "access-analyzer:Get*",
        ]
        Resource = "*"
      },
      {
        Sid      = "ViewServiceHealthAndSupport"
        Effect   = "Allow"
        Action   = ["health:Describe*", "support:Describe*"]
        Resource = "*"
      },
      {
        # Explicit deny wins over any allow, so these stay blocked even if a broader
        # policy is attached to this permission set by mistake later.
        Sid    = "DenyDestructiveAndCredentialChanges"
        Effect = "Deny"
        Action = [
          "ec2:TerminateInstances", "ec2:StopInstances", "ec2:Delete*",
          "ec2:ModifyInstanceAttribute", "ec2:AuthorizeSecurityGroup*", "ec2:RevokeSecurityGroup*",
          "iam:Create*", "iam:Delete*", "iam:Update*", "iam:Put*", "iam:Attach*", "iam:Detach*",
          "iam:Add*", "iam:Remove*", "iam:ChangePassword", "iam:ResetServiceSpecificCredential",
          "iam:EnableMFADevice", "iam:DeactivateMFADevice", "iam:ResyncMFADevice", "iam:PassRole",
          "sso:*", "sso-directory:*",
          "identitystore:Create*", "identitystore:Delete*", "identitystore:Update*",
          "organizations:*",
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_ssoadmin_permission_set_inline_policy" "helpdesk" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.helpdesk.arn
  inline_policy      = local.helpdesk_policy
}

# ---------- SecurityAnalyst (custom least privilege, SecurityAnalysts) ----------
resource "aws_ssoadmin_permission_set" "security_analyst" {
  name             = "SecurityAnalyst"
  description      = "Read-only access to security logs and findings. No write."
  instance_arn     = local.instance_arn
  session_duration = "PT4H"
}

locals {
  security_analyst_allow_actions = [
    # CloudTrail: event history lookup and trail/config read
    "cloudtrail:LookupEvents", "cloudtrail:DescribeTrails", "cloudtrail:GetTrail",
    "cloudtrail:GetTrailStatus", "cloudtrail:ListTrails", "cloudtrail:GetEventSelectors",
    "cloudtrail:GetInsightSelectors", "cloudtrail:ListTags",
    # CloudWatch Logs: read and Logs Insights queries (queries read data, they change nothing)
    "logs:DescribeLogGroups", "logs:DescribeLogStreams", "logs:GetLogEvents",
    "logs:FilterLogEvents", "logs:StartQuery", "logs:StopQuery", "logs:GetQueryResults",
    "logs:DescribeQueries", "logs:GetLogGroupFields",
    # GuardDuty
    "guardduty:Get*", "guardduty:List*", "guardduty:Describe*",
    # Security Hub
    "securityhub:Get*", "securityhub:List*", "securityhub:Describe*", "securityhub:BatchGet*",
    # AWS Config
    "config:Describe*", "config:Get*", "config:List*", "config:BatchGet*",
    "config:SelectResourceConfig",
    # IAM Access Analyzer
    "access-analyzer:Get*", "access-analyzer:List*",
  ]

  security_analyst_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadSecurityLogsAndFindings"
        Effect   = "Allow"
        Action   = local.security_analyst_allow_actions
        Resource = "*"
      },
      {
        # Analysts must not be able to blind or alter the controls they monitor.
        Sid    = "DenyTamperingWithSecurityTooling"
        Effect = "Deny"
        Action = [
          "cloudtrail:StopLogging", "cloudtrail:DeleteTrail", "cloudtrail:UpdateTrail",
          "cloudtrail:PutEventSelectors", "cloudtrail:PutInsightSelectors", "cloudtrail:CreateTrail",
          "logs:Delete*", "logs:Put*", "logs:Create*", "logs:Disassociate*",
          "guardduty:Create*", "guardduty:Delete*", "guardduty:Update*", "guardduty:Archive*",
          "guardduty:Unarchive*", "guardduty:Disassociate*", "guardduty:StopMonitoringMembers",
          "securityhub:Batch*Update*", "securityhub:Update*", "securityhub:Delete*",
          "securityhub:Disable*", "securityhub:Create*",
          "config:Delete*", "config:Put*", "config:Stop*", "config:Start*",
          "access-analyzer:Create*", "access-analyzer:Delete*", "access-analyzer:Update*",
          "access-analyzer:Apply*",
          "iam:*", "sso:*", "sso-directory:*", "identitystore:*", "organizations:*",
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_ssoadmin_permission_set_inline_policy" "security_analyst" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_analyst.arn
  inline_policy      = local.security_analyst_policy
}

locals {
  permission_set_arns = {
    AdministratorAccess = aws_ssoadmin_permission_set.administrator.arn
    ReadOnlyAccess      = aws_ssoadmin_permission_set.read_only.arn
    ViewOnlyAccess      = aws_ssoadmin_permission_set.view_only.arn
    HelpDesk            = aws_ssoadmin_permission_set.helpdesk.arn
    SecurityAnalyst     = aws_ssoadmin_permission_set.security_analyst.arn
  }
}
