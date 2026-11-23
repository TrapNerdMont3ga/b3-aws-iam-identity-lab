variable "enable_cloudtrail" {
  description = "When false (the default), this module creates no AWS resources. Set to true only after the account owner approves the design and a terraform plan."
  type        = bool
  default     = false
}

variable "aws_region" {
  description = "Home Region for the trail and the log bucket (for example us-east-1)."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix for the trail and related resource names."
  type        = string
  default     = "b3-iam-lab"
}

variable "trail_name" {
  description = "Name of the CloudTrail trail."
  type        = string
  default     = "b3-iam-lab-management-events"
}

variable "trail_bucket_name" {
  description = "Globally unique S3 bucket name for CloudTrail logs. Required when enable_cloudtrail is true. Do not include account IDs in the name if the name will appear in public docs."
  type        = string
  default     = ""

  validation {
    condition     = var.trail_bucket_name == "" || can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.trail_bucket_name))
    error_message = "trail_bucket_name must be empty or a valid S3 bucket name."
  }
}

variable "is_multi_region_trail" {
  description = "If true, the trail records management events in all enabled Regions (recommended; the first copy of management events in each Region has no CloudTrail delivery charge)."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "S3 lifecycle expiration for CloudTrail log objects, in days. Default 90 keeps retained volume small."
  type        = number
  default     = 90

  validation {
    condition     = var.log_retention_days >= 1 && var.log_retention_days <= 3650
    error_message = "log_retention_days must be between 1 and 3650."
  }
}

variable "enable_cloudwatch_logs" {
  description = "Optional CloudWatch Logs delivery. Off by default because log ingestion and storage are billed. Leave false unless the owner accepts that cost."
  type        = bool
  default     = false
}

variable "cloudwatch_logs_retention_days" {
  description = "Retention for the optional CloudWatch Logs group, if enable_cloudwatch_logs is true."
  type        = number
  default     = 90
}
