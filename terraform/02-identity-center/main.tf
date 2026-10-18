# IAM Identity Center must already be enabled (console, one time). Terraform cannot
# enable it; it reads the existing instance here.
data "aws_ssoadmin_instances" "this" {}

locals {
  instance_arn      = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  # Flatten user => [groups] into one entry per membership.
  memberships = merge([
    for username, u in var.users : {
      for g in u.groups : "${username}:${g}" => {
        username = username
        group    = g
      }
    }
  ]...)

  admin_count = length([for u in values(var.users) : u if contains(u.groups, "CloudAdmins")])
}

# Keep the privileged group small (AC-6(5)). Fails the plan if exceeded.
resource "terraform_data" "admin_group_size_guard" {
  input = local.admin_count

  lifecycle {
    precondition {
      condition     = local.admin_count <= var.max_admins
      error_message = "CloudAdmins has more members than max_admins allows. Privileged access must stay restricted to a small group."
    }
  }
}
