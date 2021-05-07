resource "aws_iam_role" "concourse_secrets_admin" {
  name = "${var.deployment}-${var.concourse_team_name}-concourse-secrets-admin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Effect = "Allow"
          Principal = {
            Federated = var.iam_oidc_provider_arn
          }
          Action = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            StringEquals = {
              "${var.oidc_host_path}:aud" = var.github_oauth_client_id
              "aws:RequestTag/t${var.trusted_github_team_id}" = "t"
            }
          }
        }, {
          Sid = "AllowPassSessionTagsAndTransitive"
          Effect = "Allow"
          Action = "sts:TagSession"
          Principal = {
            Federated = var.iam_oidc_provider_arn
          }
        }
      ],
      (length(var.allowed_cidrs) == 0 ? [] : [{
          Sid = "DisallowAssumeFromUntrustedCIDR"
          Effect = "Deny"
          Principal = {
            Federated = var.iam_oidc_provider_arn
          }
          Action = "sts:AssumeRoleWithWebIdentity"
          Condition = {
            NotIpAddress = {
              "aws:SourceIp" = var.allowed_cidrs
            }
          }
        }
      ])
    )
  })
}

resource "aws_iam_role_policy" "concourse_secrets_admin" {
  name = "${var.deployment}-${var.concourse_team_name}-concourse-secrets-admin-policy"
  role = aws_iam_role.concourse_secrets_admin.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Action = [
            "ssm:GetParameter",
            "ssm:GetParameterHistory",
            "ssm:GetParameters",
            "ssm:GetParametersByPath",
            "ssm:DeleteParameter",
            "ssm:PutParameter",
          ]
          Effect = "Allow"
          Resource = [
            "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.account.account_id}:parameter/${var.deployment}/concourse/pipelines/${var.concourse_team_name}/*"
          ]
        }, {
          Action = [
            "ssm:DeleteParameter",
            "ssm:PutParameter",
          ]
          Effect = "Deny"
          Resource = [
            "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.account.account_id}:parameter/${var.deployment}/concourse/pipelines/${var.concourse_team_name}/readonly_*"
          ]
        }, {
          Action = [
            "kms:ListKeys",
            "kms:ListAliases",
            "kms:Describe*",
            "kms:Decrypt",
            "kms:Encrypt",
          ]
          Effect = "Allow"
          Resource = var.kms_key_arn
        }
      ],
      (length(var.allowed_cidrs) == 0 ? [] : [{
          Sid = "DisallowAllFromUntrustedCIDR"
          Effect = "Deny"
          Action = "*"
          Resource = "*"
          Condition = {
            NotIpAddress = {
              "aws:SourceIp" = var.allowed_cidrs
            }
          }
        }
      ])
    )
  })
}
