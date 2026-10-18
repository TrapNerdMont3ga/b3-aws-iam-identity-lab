terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Billing metrics (AWS/Billing EstimatedCharges) are published only in us-east-1.
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project   = "b3-aws-iam-identity-lab"
      ManagedBy = "terraform"
      Purpose   = "cost-guardrail"
    }
  }
}
