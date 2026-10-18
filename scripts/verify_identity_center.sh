#!/usr/bin/env bash
# Collects read-only CLI evidence of the deployed Identity Center config into evidence/cli/.
# Account ID and alert email are replaced with placeholders before saving.
# Usage: AWS_PROFILE=... bash scripts/verify_identity_center.sh <account-id>
set -euo pipefail
ACCT="${1:?account id}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}" AWS_PAGER=""
OUT="$(cd "$(dirname "$0")/.." && pwd)/evidence/cli"
mkdir -p "$OUT"
ARN=$(aws sso-admin list-instances --query 'Instances[0].InstanceArn' --output text)
IDS=$(aws sso-admin list-instances --query 'Instances[0].IdentityStoreId' --output text)
san() { sed -E -e "s/${ACCT}/<ACCOUNT_ID>/g" -e 's/[A-Za-z0-9._%+-]+@gmail\.com/<ALERT_EMAIL>/g'; }
save() { local f="$1"; shift; { echo "\$ $*" | san; echo; "$@" 2>&1 | san; } > "$OUT/$f"; echo "wrote evidence/cli/$f"; }

save 00-caller-identity.txt aws sts get-caller-identity --query '{Account:Account,Arn:Arn}' --output table
save 01-sso-instance.txt aws sso-admin describe-instance --instance-arn "$ARN" --output json
save 02-groups.txt aws identitystore list-groups --identity-store-id "$IDS" --query 'Groups[].{Group:DisplayName,Description:Description,GroupId:GroupId}' --output table
save 03-users.txt aws identitystore list-users --identity-store-id "$IDS" --query 'Users[].{UserName:UserName,DisplayName:DisplayName,Title:Title,Email:Emails[0].Value}' --output table

{
  echo "Group memberships (resolved to usernames)"; echo
  declare -A U
  while read -r id name; do U[$id]=$name; done < <(aws identitystore list-users --identity-store-id "$IDS" --query 'Users[].[UserId,UserName]' --output text)
  while read -r gid gname; do
    for mid in $(aws identitystore list-group-memberships --identity-store-id "$IDS" --group-id "$gid" --query 'GroupMemberships[].MemberId.UserId' --output text); do
      printf '%-18s %s\n' "$gname" "${U[$mid]:-$mid}"
    done
  done < <(aws identitystore list-groups --identity-store-id "$IDS" --query 'Groups[].[GroupId,DisplayName]' --output text) | sort
} | san > "$OUT/04-group-memberships.txt"; echo "wrote evidence/cli/04-group-memberships.txt"

{
  echo "Permission sets: session duration, managed policies, inline policy"; echo
  for ps in $(aws sso-admin list-permission-sets --instance-arn "$ARN" --query 'PermissionSets[]' --output text); do
    aws sso-admin describe-permission-set --instance-arn "$ARN" --permission-set-arn "$ps" \
      --query 'PermissionSet.{Name:Name,SessionDuration:SessionDuration,Description:Description,Arn:PermissionSetArn}' --output json
    echo "Managed policies:"
    aws sso-admin list-managed-policies-in-permission-set --instance-arn "$ARN" --permission-set-arn "$ps" --query 'AttachedManagedPolicies[].Arn' --output json
    echo "Inline policy:"
    pol=$(aws sso-admin get-inline-policy-for-permission-set --instance-arn "$ARN" --permission-set-arn "$ps" --query 'InlinePolicy' --output text)
    if [ -n "$pol" ] && [ "$pol" != "None" ]; then echo "$pol" | python3 -m json.tool; else echo "(none)"; fi
    echo "----------------------------------------------------------------"
  done
} | san > "$OUT/05-permission-sets.txt"; echo "wrote evidence/cli/05-permission-sets.txt"

{
  echo "Account assignments in <ACCOUNT_ID> and provisioning status"; echo
  declare -A G
  while read -r gid gname; do G[$gid]=$gname; done < <(aws identitystore list-groups --identity-store-id "$IDS" --query 'Groups[].[GroupId,DisplayName]' --output text)
  for ps in $(aws sso-admin list-permission-sets-provisioned-to-account --instance-arn "$ARN" --account-id "$ACCT" --query 'PermissionSets[]' --output text); do
    name=$(aws sso-admin describe-permission-set --instance-arn "$ARN" --permission-set-arn "$ps" --query 'PermissionSet.Name' --output text)
    aws sso-admin list-account-assignments --instance-arn "$ARN" --account-id "$ACCT" --permission-set-arn "$ps" \
      --query 'AccountAssignments[].[PrincipalType,PrincipalId]' --output text | while read -r t pid; do
        printf '%-20s -> %-6s %-18s (provisioned to account)\n' "$name" "$t" "${G[$pid]:-$pid}"
      done
  done | sort
  echo; echo "Recent provisioning operations:"
  aws sso-admin list-permission-set-provisioning-status --instance-arn "$ARN" --query 'PermissionSetsProvisioningStatus[].{Status:Status,Created:CreatedDate}' --output table
} | san > "$OUT/06-account-assignments.txt"; echo "wrote evidence/cli/06-account-assignments.txt"

save 07-billing-alarm.txt aws cloudwatch describe-alarms --region us-east-1 --alarm-name-prefix b3-iam-lab --query 'MetricAlarms[].{Name:AlarmName,Metric:MetricName,Threshold:Threshold,State:StateValue,Period:Period}' --output table
save 08-sns-subscription.txt aws sns list-subscriptions --region us-east-1 --query 'Subscriptions[?contains(TopicArn,`b3-iam-lab`)].{Protocol:Protocol,Endpoint:Endpoint,Subscription:SubscriptionArn}' --output table
save 09-budget.txt aws budgets describe-budgets --account-id "$ACCT" --query 'Budgets[].{Name:BudgetName,Limit:BudgetLimit.Amount,Unit:BudgetLimit.Unit,TimeUnit:TimeUnit,Type:BudgetType}' --output table
