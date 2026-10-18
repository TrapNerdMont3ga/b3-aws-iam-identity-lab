# Access is granted to GROUPS, never directly to users. Joiner/mover/leaver changes
# are then just group membership changes (see docs/jml-runbook.md).
resource "aws_ssoadmin_account_assignment" "this" {
  for_each = var.group_permission_sets

  instance_arn       = local.instance_arn
  permission_set_arn = local.permission_set_arns[each.value]

  principal_id   = aws_identitystore_group.this[each.key].group_id
  principal_type = "GROUP"

  target_id   = var.target_account_id
  target_type = "AWS_ACCOUNT"

  # Inline/managed policies must exist before the permission set is provisioned.
  depends_on = [
    aws_ssoadmin_managed_policy_attachment.administrator,
    aws_ssoadmin_managed_policy_attachment.read_only,
    aws_ssoadmin_managed_policy_attachment.view_only,
    aws_ssoadmin_permission_set_inline_policy.helpdesk,
  ]
}
