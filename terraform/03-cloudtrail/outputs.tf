# These values can include account IDs and ARNs. They are for local use after apply.
# Do not paste them into the public repo without redaction. State files are git-ignored.

output "enabled" {
  description = "Whether this module was applied with enable_cloudtrail = true."
  value       = var.enable_cloudtrail
}

output "trail_name" {
  description = "CloudTrail trail name, if created."
  value       = var.enable_cloudtrail ? aws_cloudtrail.management[0].name : null
}

output "trail_arn" {
  description = "CloudTrail trail ARN, if created. Contains the account ID — redact before publishing."
  value       = var.enable_cloudtrail ? aws_cloudtrail.management[0].arn : null
  sensitive   = true
}

output "log_bucket_name" {
  description = "S3 bucket that receives CloudTrail logs, if created."
  value       = var.enable_cloudtrail ? aws_s3_bucket.cloudtrail[0].id : null
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch Logs group, if CloudWatch delivery was enabled."
  value       = var.enable_cloudtrail && var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.cloudtrail[0].name : null
}
