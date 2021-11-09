resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "a031c46782e6e6c662c2c87c76da9aa62ccabd8e" # This is a magic string, if you want to know why its so magical read this -> https://stackoverflow.com/a/69247499
  ]
}

resource "aws_iam_role" "gha_zendesk_scripts" {
  name = "gha-zendesk-scripts-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = concat(
      [
        {
          Effect = "Allow",
          Principal = {
            Federated = aws_iam_openid_connect_provider.github_actions.arn
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


resource "aws_iam_role_policy" "gha_zendesk_scripts" {
  name = "gha-zendesk-scripts-role-policy"
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
          ]
        }
      ]
    )
  })
}