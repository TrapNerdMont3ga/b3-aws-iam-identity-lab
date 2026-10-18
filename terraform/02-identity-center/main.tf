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
}
