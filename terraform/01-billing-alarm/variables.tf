variable "alert_email" {
  description = "Email address that receives billing alarm notifications. The subscription must be confirmed from the inbox."
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alert_email))
    error_message = "alert_email must be a valid email address."
  }
}

variable "threshold_usd" {
  description = "Estimated monthly charges (USD) that trigger the alarm."
  type        = number
  default     = 5

  validation {
    condition     = var.threshold_usd > 0
    error_message = "threshold_usd must be greater than 0."
  }
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
  default     = "b3-iam-lab"
}
