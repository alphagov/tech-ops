data "aws_iam_policy_document" "s3_log_bucket_policy" {
  statement {
    effect  = "Allow"
    actions = ["s3:GetBucketAcl"]
    resources = [
      "arn:aws:s3:::${local.cloudtrail_bucket_name}"
    ]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }

  statement {
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
      "arn:aws:s3:::${local.cloudtrail_bucket_name}/AWSLogs/*"
    ]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_s3_bucket" "s3-object-logging" {
  bucket        = local.cloudtrail_bucket_name
  force_destroy = true

  tags = merge(local.tags, map("Name", local.cloudtrail_bucket_name))

  policy = data.aws_iam_policy_document.s3_log_bucket_policy.json
}
