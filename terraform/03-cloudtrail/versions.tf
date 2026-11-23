terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Home region for the trail and the log bucket. A multi-Region trail still
# records events in other enabled Regions and delivers them here.
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "b3-aws-iam-identity-lab"
      ManagedBy = "terraform"
      Scenario  = "OptiPrim3"
      Purpose   = "cloudtrail-management-events"
    }
  }
}
