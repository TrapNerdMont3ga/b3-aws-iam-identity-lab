output "identity_store_id" {
  description = "Identity store ID of the Identity Center instance."
  value       = local.identity_store_id
}

output "group_ids" {
  description = "Group name => group ID."
  value       = { for k, g in aws_identitystore_group.this : k => g.group_id }
}

output "user_ids" {
  description = "Username => user ID."
  value       = { for k, u in aws_identitystore_user.this : k => u.user_id }
}

output "permission_set_arns" {
  description = "Permission set name => ARN."
  value       = local.permission_set_arns
}

output "group_assignments" {
  description = "Group => permission set assigned in the target account."
  value       = var.group_permission_sets
}

output "expected_memberships" {
  description = "Username => groups as defined in code. Used by scripts/check_membership_drift.py."
  value       = { for k, u in var.users : k => sort(u.groups) }
}
