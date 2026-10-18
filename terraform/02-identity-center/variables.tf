# Scenario: OptiPrim3 (fictional logistics company). This configuration controls workforce
# access to the AWS account that hosts OptiPrim3's load-documentation app (bills of lading,
# load photos, delivery receipts). All people below are fictional.

variable "identity_center_region" {
  description = "AWS region where IAM Identity Center is enabled."
  type        = string
  default     = "us-east-1"
}

variable "target_account_id" {
  description = "12-digit ID of the OptiPrim3 load-documentation app account that receives the account assignments. Supplied via terraform.tfvars; never hardcoded."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.target_account_id))
    error_message = "target_account_id must be a 12-digit AWS account ID."
  }
}

variable "email_domain" {
  description = "Domain used for the fictional users' email addresses."
  type        = string
  default     = "example.com"
}

variable "evidence_bucket_name" {
  description = "Optional S3 bucket holding approved compliance evidence. When set, ReadOnlyAuditors can list and read objects under evidence_prefix only. Leave empty to skip."
  type        = string
  default     = ""

  validation {
    condition     = var.evidence_bucket_name == "" || can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.evidence_bucket_name))
    error_message = "evidence_bucket_name must be empty or a valid S3 bucket name."
  }
}

variable "evidence_prefix" {
  description = "Prefix inside the evidence bucket that holds approved evidence (no leading slash, trailing slash required)."
  type        = string
  default     = "approved-evidence/"

  validation {
    condition     = can(regex("^[A-Za-z0-9!_.*'()-]+(/[A-Za-z0-9!_.*'()-]+)*/$", var.evidence_prefix))
    error_message = "evidence_prefix must not start with '/' and must end with '/'."
  }
}

variable "max_admins" {
  description = "Maximum number of users allowed in CloudAdmins. Keeps the privileged group small."
  type        = number
  default     = 2
}

variable "groups" {
  description = "Identity Center groups (name => description)."
  type        = map(string)
  default = {
    HelpDesk         = "OptiPrim3 service desk: view-only troubleshooting of EC2 and IAM. No changes."
    CloudAdmins      = "OptiPrim3 cloud administrators: full admin, 1 hour sessions, small group, MFA required."
    SecurityAnalysts = "OptiPrim3 security operations: read-only access to security logs and findings."
    ReadOnlyAuditors = "Internal audit / GRC: resource metadata plus read access to approved compliance evidence."
    Developers       = "Load-documentation app developers: read-only access to the app account."
  }
}

variable "users" {
  description = "Fictional OptiPrim3 users. Key = Identity Center username. 'groups' lists group memberships."
  type = map(object({
    given_name  = string
    family_name = string
    title       = string
    groups      = list(string)
  }))
  default = {
    "jdoe.helpdesk" = {
      given_name  = "Jane"
      family_name = "Doe"
      title       = "Service Desk Analyst II"
      groups      = ["HelpDesk"]
    }
    "tnguyen.helpdesk" = {
      given_name  = "Tom"
      family_name = "Nguyen"
      title       = "Service Desk Analyst I"
      groups      = ["HelpDesk"]
    }
    "asmith.admin" = {
      given_name  = "Alex"
      family_name = "Smith"
      title       = "Cloud Administrator"
      groups      = ["CloudAdmins"]
    }
    "jgarcia.secanalyst" = {
      given_name  = "Jordan"
      family_name = "Garcia"
      title       = "Security Analyst"
      groups      = ["SecurityAnalysts"]
    }
    "mlee.auditor" = {
      given_name  = "Morgan"
      family_name = "Lee"
      title       = "IT Compliance Auditor"
      groups      = ["ReadOnlyAuditors"]
    }
    "rpatel.dev" = {
      given_name  = "Ravi"
      family_name = "Patel"
      title       = "Software Developer, Load Docs"
      groups      = ["Developers"]
    }
    "kbrown.dev" = {
      given_name  = "Kim"
      family_name = "Brown"
      title       = "Software Developer, Load Docs"
      groups      = ["Developers"]
    }
  }

  # Separation of duties: people who administer the account must not also be the
  # people who audit it or monitor it for misuse.
  validation {
    condition = alltrue([
      for u in values(var.users) :
      !(contains(u.groups, "CloudAdmins") && (contains(u.groups, "ReadOnlyAuditors") || contains(u.groups, "SecurityAnalysts")))
    ])
    error_message = "Separation of duties violation: a CloudAdmins member cannot also be in ReadOnlyAuditors or SecurityAnalysts."
  }
}

variable "group_permission_sets" {
  description = "Which permission set each group is assigned in the target account (group => permission set key)."
  type        = map(string)
  default = {
    HelpDesk         = "HelpDesk"
    CloudAdmins      = "AdministratorAccess"
    SecurityAnalysts = "SecurityAnalyst"
    ReadOnlyAuditors = "ViewOnlyAccess"
    Developers       = "ReadOnlyAccess"
  }
}
