output "sns_topic_arn" {
  description = "ARN of the billing alerts SNS topic."
  value       = aws_sns_topic.billing_alerts.arn
}

output "alarm_name" {
  description = "Name of the CloudWatch billing alarm."
  value       = aws_cloudwatch_metric_alarm.estimated_charges.alarm_name
}

output "budget_name" {
  description = "Name of the monthly AWS Budget."
  value       = aws_budgets_budget.monthly.name
}
