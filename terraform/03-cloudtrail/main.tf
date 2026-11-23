# POAM-01 CloudTrail design (see compliance/cloudtrail-trail-design.md).
# Default: enable_cloudtrail = false, so terraform apply in this directory
# creates nothing until the account owner approves a plan with the flag set
# to true. Do not apply without that approval. No data events, Insights, or Lake.

data "aws_caller_identity" "current" {
  count = var.enable_cloudtrail ? 1 : 0
}

data "aws_partition" "current" {
  count = var.enable_cloudtrail ? 1 : 0
}

data "aws_region" "current" {
  count = var.enable_cloudtrail ? 1 : 0
}

locals {
  trail_arn = var.enable_cloudtrail ? "arn:${data.aws_partition.current[0].id}:cloudtrail:${data.aws_region.current[0].name}:${data.aws_caller_identity.current[0].account_id}:trail/${var.trail_name}" : null
  # CloudTrail writes under AWSLogs/<account-id>/ (optional prefix omitted).
  log_prefix = var.enable_cloudtrail ? "AWSLogs/${data.aws_caller_identity.current[0].account_id}/*" : null
}

resource "terraform_data" "require_bucket_name" {
  count = var.enable_cloudtrail ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.trail_bucket_name != ""
      error_message = "Set trail_bucket_name to a globally unique S3 bucket name before enabling CloudTrail."
    }
  }
}

resource "aws_s3_bucket" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = var.trail_bucket_name

  # A log bucket should not be destroyed casually. The owner can remove this
  # protection later if they are tearing the lab down on purpose.
  lifecycle {
    prevent_destroy = true
  }

  depends_on = [terraform_data.require_bucket_name]
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_ownership_controls" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id

  rule {
    id     = "expire-cloudtrail-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = var.log_retention_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "cloudtrail_bucket" {
  count = var.enable_cloudtrail ? 1 : 0

  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail[0].arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail[0].arn}/${local.log_prefix}"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id
  policy = data.aws_iam_policy_document.cloudtrail_bucket[0].json

  depends_on = [aws_s3_bucket_public_access_block.cloudtrail]
}

# Optional CloudWatch Logs delivery (off by default).
data "aws_iam_policy_document" "cloudtrail_cwl_assume" {
  count = var.enable_cloudtrail && var.enable_cloudwatch_logs ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cloudtrail_cwl" {
  count              = var.enable_cloudtrail && var.enable_cloudwatch_logs ? 1 : 0
  name               = "${var.name_prefix}-cloudtrail-cloudwatch-logs"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_cwl_assume[0].json
}

data "aws_iam_policy_document" "cloudtrail_cwl" {
  count = var.enable_cloudtrail && var.enable_cloudwatch_logs ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.cloudtrail[0].arn}:*"]
  }
}

resource "aws_iam_role_policy" "cloudtrail_cwl" {
  count  = var.enable_cloudtrail && var.enable_cloudwatch_logs ? 1 : 0
  name   = "cloudtrail-cloudwatch-logs"
  role   = aws_iam_role.cloudtrail_cwl[0].id
  policy = data.aws_iam_policy_document.cloudtrail_cwl[0].json
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  count             = var.enable_cloudtrail && var.enable_cloudwatch_logs ? 1 : 0
  name              = "/aws/cloudtrail/${var.trail_name}"
  retention_in_days = var.cloudwatch_logs_retention_days
}

resource "aws_cloudtrail" "management" {
  count = var.enable_cloudtrail ? 1 : 0

  name                          = var.trail_name
  s3_bucket_name                = aws_s3_bucket.cloudtrail[0].id
  include_global_service_events = true
  is_multi_region_trail         = var.is_multi_region_trail
  enable_log_file_validation    = true
  enable_logging                = true
  is_organization_trail         = false

  # Management events only. No data_resource blocks, so no data events.
  # No insight_selector, so Insights stays off.
  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  cloud_watch_logs_group_arn = var.enable_cloudwatch_logs ? "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*" : null
  cloud_watch_logs_role_arn  = var.enable_cloudwatch_logs ? aws_iam_role.cloudtrail_cwl[0].arn : null

  depends_on = [
    aws_s3_bucket_policy.cloudtrail,
    aws_s3_bucket_server_side_encryption_configuration.cloudtrail,
    aws_iam_role_policy.cloudtrail_cwl,
  ]
}
