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

resource "aws_iam_role_policy_attachment" "concourse_sts_rotation_lambda_execution" {
  role       = var.lambda_execution_role_name
  policy_arn = aws_iam_policy.concourse_sts_rotation_lambda_execution.arn
}

