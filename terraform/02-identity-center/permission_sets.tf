# ---------- AdministratorAccess (CloudAdmins) ----------
resource "aws_ssoadmin_permission_set" "administrator" {
  name             = "AdministratorAccess"
  description      = "Full admin. Short 1h session to limit exposure of privileged credentials."
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
  description      = "Read-only access to resources and data."
  instance_arn     = local.instance_arn
  session_duration = "PT4H"
}

resource "aws_ssoadmin_managed_policy_attachment" "read_only" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.read_only.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ---------- ViewOnlyAccess (ReadOnlyAuditors) ----------
# ViewOnlyAccess lists/describes resource metadata without reading data contents
# (e.g. no S3 GetObject), which fits an access-review / audit role.
resource "aws_ssoadmin_permission_set" "view_only" {
  name             = "ViewOnlyAccess"
  description      = "Auditor view-only access to resource metadata."
  instance_arn     = local.instance_arn
  session_duration = "PT2H"
}

resource "aws_ssoadmin_managed_policy_attachment" "view_only" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.view_only.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
}

# ---------- HelpDesk (custom least privilege) ----------
resource "aws_ssoadmin_permission_set" "helpdesk" {
  name             = "HelpDesk"
  description      = "Custom least-privilege: view EC2 and IAM for troubleshooting; no changes."
  instance_arn     = local.instance_arn
  session_duration = "PT4H"
}

data "aws_iam_policy_document" "helpdesk" {
  statement {
    sid    = "ViewEC2ForTroubleshooting"
    effect = "Allow"
    actions = [
      "ec2:Describe*",
      "ec2:GetConsoleOutput",
      "ec2:GetConsoleScreenshot",
      "elasticloadbalancing:Describe*",
      "autoscaling:Describe*",
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*",
      "ssm:DescribeInstanceInformation",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ViewIAMForAccessQuestions"
    effect = "Allow"
    actions = [
      "iam:Get*",
      "iam:List*",
      "iam:GenerateCredentialReport",
      "iam:GenerateServiceLastAccessedDetails",
      "access-analyzer:List*",
      "access-analyzer:Get*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ViewServiceHealthAndSupport"
    effect = "Allow"
    actions = [
      "health:Describe*",
      "support:Describe*",
    ]
    resources = ["*"]
  }

  # Explicit deny wins over any allow, so these stay blocked even if a broader
  # policy is attached to this permission set by mistake later.
  statement {
    sid    = "DenyDestructiveAndCredentialChanges"
    effect = "Deny"
    actions = [
      "ec2:TerminateInstances",
      "ec2:StopInstances",
      "ec2:Delete*",
      "ec2:ModifyInstanceAttribute",
      "ec2:AuthorizeSecurityGroup*",
      "ec2:RevokeSecurityGroup*",
      "iam:Create*",
      "iam:Delete*",
      "iam:Update*",
      "iam:Put*",
      "iam:Attach*",
      "iam:Detach*",
      "iam:Add*",
      "iam:Remove*",
      "iam:ChangePassword",
      "iam:ResetServiceSpecificCredential",
      "iam:EnableMFADevice",
      "iam:DeactivateMFADevice",
      "iam:ResyncMFADevice",
      "iam:PassRole",
      "sso:*",
      "sso-directory:*",
      "identitystore:Create*",
      "identitystore:Delete*",
      "identitystore:Update*",
      "organizations:*",
    ]
    resources = ["*"]
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "helpdesk" {
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.helpdesk.arn
  inline_policy      = data.aws_iam_policy_document.helpdesk.json
}

locals {
  permission_set_arns = {
    AdministratorAccess = aws_ssoadmin_permission_set.administrator.arn
    ReadOnlyAccess      = aws_ssoadmin_permission_set.read_only.arn
    ViewOnlyAccess      = aws_ssoadmin_permission_set.view_only.arn
    HelpDesk            = aws_ssoadmin_permission_set.helpdesk.arn
  }
}
