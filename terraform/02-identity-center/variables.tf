variable "identity_center_region" {
  description = "AWS region where IAM Identity Center is enabled."
  type        = string
  default     = "us-east-1"
}

variable "target_account_id" {
  description = "12-digit AWS account ID that receives the account assignments (the lab/management account). Supplied via terraform.tfvars; never hardcoded."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.target_account_id))
    error_message = "target_account_id must be a 12-digit AWS account ID."
  }
}

variable "email_domain" {
  description = "Domain used for the fictional lab users' email addresses. Use a domain you control if you want to receive the invitation emails (e.g. plus-addressing on your own mailbox)."
  type        = string
  default     = "example.com"
}

variable "groups" {
  description = "Identity Center groups (name => description)."
  type        = map(string)
  default = {
    HelpDesk         = "Tier 1/2 service desk: view-only troubleshooting of EC2 and IAM. No destructive actions."
    CloudAdmins      = "Cloud administrators: full administrative access, 1 hour sessions."
    ReadOnlyAuditors = "Internal audit / GRC: view-only metadata access for access reviews."
    Developers       = "Application developers: read-only access to the lab account."
  }
}

variable "users" {
  description = "Fictional lab users. Key = Identity Center username. 'groups' lists group memberships."
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
    "mlee.auditor" = {
      given_name  = "Morgan"
      family_name = "Lee"
      title       = "IT Auditor"
      groups      = ["ReadOnlyAuditors"]
    }
    "rpatel.dev" = {
      given_name  = "Ravi"
      family_name = "Patel"
      title       = "Software Developer"
      groups      = ["Developers"]
    }
    "kbrown.dev" = {
      given_name  = "Kim"
      family_name = "Brown"
      title       = "Software Developer"
      groups      = ["Developers"]
    }
  }

  # Separation of duties guardrail: the people who administer access
  # must not be the people who audit it.
  validation {
    condition = alltrue([
      for u in values(var.users) :
      !(contains(u.groups, "CloudAdmins") && contains(u.groups, "ReadOnlyAuditors"))
    ])
    error_message = "Separation of duties violation: a user cannot be in both CloudAdmins and ReadOnlyAuditors."
  }
}

variable "group_permission_sets" {
  description = "Which permission set each group is assigned in the target account (group => permission set key)."
  type        = map(string)
  default = {
    HelpDesk         = "HelpDesk"
    CloudAdmins      = "AdministratorAccess"
    ReadOnlyAuditors = "ViewOnlyAccess"
    Developers       = "ReadOnlyAccess"
  }
}
