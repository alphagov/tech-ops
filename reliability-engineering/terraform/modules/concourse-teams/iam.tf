resource "aws_iam_role" "concourse_team" {
  for_each = toset(var.team_names)

  name = "${var.deployment}-${each.key}-concourse-team"

  assume_role_policy = <<-ARP
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow"
      }, {
        "Action": "sts:AssumeRole",
        "Principal": {
          "AWS": "${aws_iam_role.concourse_sts_rotation_lambda_execution.arn}"
        },
        "Effect": "Allow"
      }
    ]
  }
ARP
}

resource "aws_iam_policy" "concourse_team" {
  for_each = toset(var.team_names)

  name = "${var.deployment}-${each.key}-concourse-team"

  policy = <<-POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        "Effect": "Allow",
        "Resource": [
          "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.account.account_id}:parameter/${var.deployment}/concourse/worker/${each.key}/*"
        ]
      }, {
        "Action": [
          "ssm:GetParameter",
          "ssm:GetParameterHistory",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "ssm:DeleteParameter",
          "ssm:PutParameter"
        ],
        "Effect": "Allow",
        "Resource": [
          "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.account.account_id}:parameter/${var.deployment}/concourse/pipelines/${each.key}/*"
        ]
      }, {
        "Action": [
          "ssm:DeleteParameter",
          "ssm:PutParameter"
        ],
        "Effect": "Deny",
        "Resource": [
          "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.account.account_id}:parameter/${var.deployment}/concourse/pipelines/${each.key}/readonly_*"
        ]
      }, {
        "Effect": "Allow",
        "Action": [
          "kms:ListKeys",
          "kms:ListAliases",
          "kms:Describe*",
          "kms:Decrypt"
        ],
        "Resource": "${var.kms_key_arn}"
      }, {
        "Effect": "Allow",
        "Action": ["sts:AssumeRole"],
        "Resource": "*"
      }
    ]
  }
POLICY
}

resource "aws_iam_role_policy_attachment" "concourse_team" {
  for_each   = toset(var.team_names)
  role       = aws_iam_role.concourse_team[each.key].name
  policy_arn = aws_iam_policy.concourse_team[each.key].arn
}

resource "aws_iam_policy" "concourse_sts_rotation_lambda_execution" {
  name = "${var.deployment}-concourse-sts-rotation-lambda-execution"

  policy = <<-POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "ssm:PutParameter"
        ],
        "Effect": "Allow",
        "Resource": [
          "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.account.account_id}:parameter/${var.deployment}/concourse/pipelines/*/readonly_access_key_id",
          "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.account.account_id}:parameter/${var.deployment}/concourse/pipelines/*/readonly_secret_access_key",
          "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.account.account_id}:parameter/${var.deployment}/concourse/pipelines/*/readonly_session_token"
        ]
      }, {
        "Effect": "Allow",
        "Action": [
          "kms:ListKeys",
          "kms:ListAliases",
          "kms:Describe*",
          "kms:Decrypt",
          "kms:Encrypt"
        ],
        "Resource": [
          "${var.kms_key_arn}"
        ]
      }, {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        "Resource": [
          "arn:aws:logs:*:*:*"
        ]
      }, {
        "Effect": "Allow",
        "Action": [
          "sts:AssumeRole"
        ],
        "Resource": "*"
      }
    ]
  }
POLICY
}

resource "aws_iam_role" "concourse_sts_rotation_lambda_execution" {
  name               = "${var.deployment}-sts-rotation-lambda-execution"
  assume_role_policy = <<-ARP
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow"
      }
    ]
  }
ARP
}

resource "aws_iam_role_policy_attachment" "concourse_sts_rotation_lambda_execution" {
  role       = aws_iam_role.concourse_sts_rotation_lambda_execution.name
  policy_arn = aws_iam_policy.concourse_sts_rotation_lambda_execution.arn
}
