resource "aws_iam_role" "gha_zendesk_scripts" {
  name = "${var.deployment}-gha-zendesk-scripts-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = concat(
      [
        {
          Effect = "Allow",
          Principal = {
            Federated = var.github_actions_openid_arn
          },
          Action = "sts:AssumeRoleWithWebIdentity",
          Condition = {
              StringEquals = {
                "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
                "token.actions.githubusercontent.com:sub": "repo:alphagov/zendesk-scripts:${var.github_oidc_claim}"
              }
          }
        }
      ]
    )
  })
}

resource "aws_s3_bucket" "zendesk_deduplication_logs" {
  bucket = "${var.deployment}-zendesk-dedup-logs"
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}


resource "aws_iam_role_policy" "gha_zendesk_scripts" {
  name = "${var.deployment}-gha-zendesk-scripts-role-policy"
  role = aws_iam_role.gha_zendesk_scripts.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Action = [
            "s3:PutObject",
            "s3:PutObjectAcl",
          ]
          Effect = "Allow"
          Resource = [
            "${var.zendesk_scripts_output_bucket}",
            "${var.zendesk_scripts_output_bucket}/*",
            "${aws_s3_bucket.zendesk_deduplication_logs.arn}",
            "${aws_s3_bucket.zendesk_deduplication_logs.arn}/*",
          ]
        }
      ]
    )
  })
}
