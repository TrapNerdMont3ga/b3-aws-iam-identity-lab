terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Use the region where IAM Identity Center was enabled (Settings > Region in the console).
provider "aws" {
  region = var.identity_center_region

  default_tags {
    tags = {
      Project   = "b3-aws-iam-identity-lab"
      ManagedBy = "terraform"
    }
  }
}
