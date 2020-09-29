resource "aws_iam_policy" "concourse_web" {
  name = "${var.deployment}-concourse-web"

  policy = <<-POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }, {
        "Action": [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        "Effect": "Allow",
        "Resource": [
          "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.account.account_id}:parameter/${var.deployment}/concourse/web/*",
          "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.account.account_id}:parameter/${var.deployment}/concourse/pipelines/*"
        ]
      }, {
        "Effect": "Allow",
        "Action": [
          "kms:ListKeys",
          "kms:ListAliases",
          "kms:Describe*",
          "kms:Decrypt"
        ],
        "Resource": [
          "${var.web_kms_key_arn}",
          "${var.worker_kms_key_arn}"
        ]
      }, {
        "Effect": "Allow",
        "Action": [
          "s3:AbortMultipartUpload",
          "s3:DeleteObject",
          "s3:DeleteObjectTagging",
          "s3:DeleteObjectVersion",
          "s3:DeleteObjectVersionTagging",
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:GetObjectTagging",
          "s3:GetObjectTorrent",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectVersionTorrent",
          "s3:ListMultipartUploadParts",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectTagging",
          "s3:PutObjectVersionAcl",
          "s3:PutObjectVersionTagging",
          "s3:RestoreObject"
        ],
        "Resource": [
          "${aws_s3_bucket.concourse_web.arn}",
          "${aws_s3_bucket.concourse_web.arn}/*"
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
      }
    ]
  }
POLICY
}

resource "aws_iam_role_policy_attachment" "concourse_web_concourse_web" {
  role       = var.web_iam_role_name
  policy_arn = aws_iam_policy.concourse_web.arn
}

resource "aws_iam_instance_profile" "concourse_web" {
  name = var.web_iam_role_name
  role = var.web_iam_role_name
}


resource "aws_iam_role" "concourse_team" {
  for_each = toset(var.worker_team_names)

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
  for_each = toset(var.worker_team_names)

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
        "Resource": "${var.worker_kms_key_arn}"
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
  for_each   = toset(var.worker_team_names)
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
          "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.account.account_id}:parameter/${var.deployment}/concourse/pipelines/*/access_key_id",
          "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.account.account_id}:parameter/${var.deployment}/concourse/pipelines/*/secret_access_key",
          "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.account.account_id}:parameter/${var.deployment}/concourse/pipelines/*/session_token"
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
          "${var.worker_kms_key_arn}"
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
        "Resource": [
          "arn:aws:iam::${data.aws_caller_identity.account.account_id}:role/${var.deployment}-*-concourse-worker"
        ]
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
