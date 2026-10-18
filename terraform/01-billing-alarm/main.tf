# Step 1 of the lab: create a cost guardrail BEFORE building anything else.
# Prerequisite (console, one time): Billing and Cost Management > Billing preferences >
# enable "Receive CloudWatch billing alerts". Without it the metric never populates.

resource "aws_sns_topic" "billing_alerts" {
  name = "${var.name_prefix}-billing-alerts"
}

resource "aws_sns_topic_subscription" "billing_email" {
  topic_arn = aws_sns_topic.billing_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "estimated_charges" {
  alarm_name          = "${var.name_prefix}-estimated-charges-over-${var.threshold_usd}-usd"
  alarm_description   = "Estimated AWS charges for the month exceeded ${var.threshold_usd} USD."
  namespace           = "AWS/Billing"
  metric_name         = "EstimatedCharges"
  statistic           = "Maximum"
  period              = 21600 # 6 hours; billing data updates a few times per day
  evaluation_periods  = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.threshold_usd
  treat_missing_data  = "notBreaching"

  dimensions = {
    Currency = "USD"
  }

  alarm_actions = [aws_sns_topic.billing_alerts.arn]
  ok_actions    = [aws_sns_topic.billing_alerts.arn]
}

# Belt and braces: an AWS Budget uses Cost Explorer data (includes charges the CloudWatch
# metric can lag on) and emails directly. Budgets without actions are free.
resource "aws_budgets_budget" "monthly" {
  name         = "${var.name_prefix}-monthly-${var.threshold_usd}-usd"
  budget_type  = "COST"
  limit_amount = format("%.2f", var.threshold_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}
