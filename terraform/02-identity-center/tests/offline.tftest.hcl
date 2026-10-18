# Offline tests: run with `terraform test` (no AWS credentials needed; provider is mocked).

mock_provider "aws" {
  mock_data "aws_ssoadmin_instances" {
    defaults = {
      arns               = ["arn:aws:sso:::instance/ssoins-0000000000000000"]
      identity_store_ids = ["d-0000000000"]
    }
  }
}

variables {
  target_account_id = "111111111111"
}

run "plans_expected_resources" {
  command = plan

  assert {
    condition     = length(aws_identitystore_group.this) == 5
    error_message = "Expected 5 groups."
  }

  assert {
    condition     = length(aws_identitystore_user.this) == 7
    error_message = "Expected 7 example users."
  }

  assert {
    condition     = length(aws_ssoadmin_account_assignment.this) == 5
    error_message = "Expected one account assignment per group."
  }

  assert {
    condition     = alltrue([for a in aws_ssoadmin_account_assignment.this : a.principal_type == "GROUP"])
    error_message = "Access must be assigned to groups, not individual users."
  }

  assert {
    condition     = var.group_permission_sets["SecurityAnalysts"] == "SecurityAnalyst" && contains(keys(aws_ssoadmin_account_assignment.this), "SecurityAnalysts")
    error_message = "SecurityAnalysts must be assigned the SecurityAnalyst permission set."
  }
}

run "session_durations" {
  command = plan

  assert {
    condition     = aws_ssoadmin_permission_set.administrator.session_duration == "PT1H"
    error_message = "AdministratorAccess session must be 1 hour."
  }

  assert {
    condition     = aws_ssoadmin_permission_set.view_only.session_duration == "PT2H"
    error_message = "Auditor session must be 2 hours."
  }

  assert {
    condition = alltrue([
      aws_ssoadmin_permission_set.helpdesk.session_duration == "PT4H",
      aws_ssoadmin_permission_set.security_analyst.session_duration == "PT4H",
      aws_ssoadmin_permission_set.read_only.session_duration == "PT4H",
    ])
    error_message = "HelpDesk, SecurityAnalyst and ReadOnly sessions must be 4 hours."
  }
}

run "security_analyst_is_read_only" {
  command = plan

  # Every allowed action must be a read verb (Get/List/Describe/BatchGet/Lookup/Filter/Select)
  # or a Logs Insights query control (StartQuery/StopQuery), which reads data but changes nothing.
  assert {
    condition = alltrue(flatten([
      for s in jsondecode(aws_ssoadmin_permission_set_inline_policy.security_analyst.inline_policy).Statement : [
        for a in s.Action : can(regex("^[a-z0-9-]+:(Get|List|Describe|BatchGet|Lookup|Filter|Select|StartQuery$|StopQuery$)", a))
      ] if s.Effect == "Allow"
    ]))
    error_message = "SecurityAnalyst allows a non-read action."
  }

  assert {
    condition = alltrue([
      for a in ["cloudtrail:StopLogging", "cloudtrail:DeleteTrail", "guardduty:Delete*", "config:Stop*", "logs:Delete*", "iam:*"] :
      contains(flatten([
        for s in jsondecode(aws_ssoadmin_permission_set_inline_policy.security_analyst.inline_policy).Statement :
        s.Action if s.Effect == "Deny"
      ]), a)
    ])
    error_message = "SecurityAnalyst must explicitly deny tampering with security tooling."
  }
}

run "helpdesk_denies_destructive" {
  command = plan

  assert {
    condition = alltrue([
      for a in ["ec2:TerminateInstances", "iam:Create*", "iam:Delete*", "sso:*"] :
      contains(flatten([
        for s in jsondecode(aws_ssoadmin_permission_set_inline_policy.helpdesk.inline_policy).Statement :
        s.Action if s.Effect == "Deny"
      ]), a)
    ])
    error_message = "HelpDesk must explicitly deny destructive and credential actions."
  }
}

run "no_evidence_policy_by_default" {
  command = plan

  assert {
    condition     = length(aws_ssoadmin_permission_set_inline_policy.view_only_evidence) == 0
    error_message = "No evidence bucket policy should be created when evidence_bucket_name is empty."
  }
}

run "auditor_evidence_scoped_to_prefix" {
  command = plan

  variables {
    evidence_bucket_name = "optiprim3-compliance-evidence-example"
    evidence_prefix      = "approved-evidence/"
  }

  assert {
    condition     = length(aws_ssoadmin_permission_set_inline_policy.view_only_evidence) == 1
    error_message = "Evidence policy should be created when a bucket is set."
  }

  assert {
    condition = contains(
      [for s in jsondecode(aws_ssoadmin_permission_set_inline_policy.view_only_evidence[0].inline_policy).Statement : s.Resource if s.Sid == "ReadApprovedEvidenceObjects"],
      "arn:aws:s3:::optiprim3-compliance-evidence-example/approved-evidence/*"
    )
    error_message = "Auditor object read must be limited to the approved evidence prefix."
  }
}

run "rejects_bad_account_id" {
  command = plan

  variables {
    target_account_id = "12345"
  }

  expect_failures = [var.target_account_id]
}

run "rejects_admin_auditor_combo" {
  command = plan

  variables {
    users = {
      "bad.combo" = {
        given_name  = "Bad"
        family_name = "Combo"
        title       = "Admin and Auditor"
        groups      = ["CloudAdmins", "ReadOnlyAuditors"]
      }
    }
  }

  expect_failures = [var.users]
}

run "rejects_admin_security_analyst_combo" {
  command = plan

  variables {
    users = {
      "bad.combo" = {
        given_name  = "Bad"
        family_name = "Combo"
        title       = "Admin and Security Analyst"
        groups      = ["CloudAdmins", "SecurityAnalysts"]
      }
    }
  }

  expect_failures = [var.users]
}

run "rejects_too_many_admins" {
  command = plan

  variables {
    max_admins = 1
    users = {
      "admin1.admin" = { given_name = "A", family_name = "One", title = "Admin", groups = ["CloudAdmins"] }
      "admin2.admin" = { given_name = "B", family_name = "Two", title = "Admin", groups = ["CloudAdmins"] }
    }
  }

  expect_failures = [terraform_data.admin_group_size_guard]
}
