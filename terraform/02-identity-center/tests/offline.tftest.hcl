# Offline tests: run with `terraform test` (no AWS credentials needed; provider is mocked).

mock_provider "aws" {
  mock_data "aws_ssoadmin_instances" {
    defaults = {
      arns               = ["arn:aws:sso:::instance/ssoins-0000000000000000"]
      identity_store_ids = ["d-0000000000"]
    }
  }
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  target_account_id = "111111111111"
}

run "plans_expected_resources" {
  command = plan

  assert {
    condition     = length(aws_identitystore_group.this) == 4
    error_message = "Expected 4 groups."
  }

  assert {
    condition     = length(aws_identitystore_user.this) == 6
    error_message = "Expected 6 example users."
  }

  assert {
    condition     = aws_ssoadmin_permission_set.administrator.session_duration == "PT1H"
    error_message = "AdministratorAccess session must be 1 hour."
  }

  assert {
    condition     = alltrue([for a in aws_ssoadmin_account_assignment.this : a.principal_type == "GROUP"])
    error_message = "Access must be assigned to groups, not individual users."
  }
}

run "rejects_bad_account_id" {
  command = plan

  variables {
    target_account_id = "12345"
  }

  expect_failures = [var.target_account_id]
}

run "rejects_separation_of_duties_violation" {
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
