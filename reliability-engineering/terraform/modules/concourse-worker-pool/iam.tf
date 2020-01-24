resource "aws_iam_policy" "concourse_worker_base" {
  name = "${var.deployment}-${var.name}-concourse-worker-base"

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
          "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.account.account_id}:parameter/${var.deployment}/concourse/worker/${var.name}/*"
        ]
      }, {
        "Action": [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "ssm:DeleteParameter",
          "ssm:PutParameter"
        ],
        "Effect": "Allow",
        "Resource": [
          "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.account.account_id}:parameter/${var.deployment}/concourse/pipelines/${var.name}/*"
        ]
      }, {
        "Action": [
          "ssm:DeleteParameter",
          "ssm:PutParameter"
        ],
        "Effect": "Deny",
        "Resource": [
          "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.account.account_id}:parameter/${var.deployment}/concourse/pipelines/${var.name}/readonly_*"
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
      }, {
        "Effect": "Allow",
        "Action": [
          "s3:AbortMultipartUpload",
          "s3:DeleteObject",
          "s3:DeleteObjectTagging",
          "s3:DeleteObjectVersion",
          "s3:DeleteObjectVersionTagging",
          "s3:GetBucketVersioning",
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
          "s3:RestoreObject",
          "s3:ListBucket",
          "s3:ListBucketVersions"
        ],
        "Resource": [
          "${aws_s3_bucket.concourse_worker_private.arn}",
          "${aws_s3_bucket.concourse_worker_private.arn}/*",
          "${aws_s3_bucket.concourse_worker_public.arn}",
          "${aws_s3_bucket.concourse_worker_public.arn}/*"
        ]
      }, {
        "Effect": "Deny",
        "Action": [
          "s3:DeleteObject",
          "s3:DeleteObjectTagging",
          "s3:DeleteObjectVersion",
          "s3:DeleteObjectVersionTagging",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectTagging",
          "s3:PutObjectVersionAcl",
          "s3:PutObjectVersionTagging",
          "s3:RestoreObject"
        ],
        "Resource": [
          "${aws_s3_bucket.concourse_worker_private.arn}/readonly/*",
          "${aws_s3_bucket.concourse_worker_public.arn}/readonly/*"
        ]
      }, {
        "Effect": "Allow",
        "Action": [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:ListImages",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ],
        "Resource": [
          "${aws_ecr_repository.concourse_worker_private.arn}",
          "${aws_ecr_repository.concourse_worker_private.arn}/*"
        ]
      }, {
        "Effect": "Allow",
        "Action": ["ecr:GetAuthorizationToken"],
        "Resource": "*"
      }
    ]
  }
POLICY
}

resource "aws_iam_role_policy_attachment" "concourse_worker_concourse_worker_base" {
  role       = var.worker_iam_role_name
  policy_arn = aws_iam_policy.concourse_worker_base.arn
}

resource "aws_iam_role_policy_attachment" "concourse_worker_additional" {
  count = length(var.additional_concourse_worker_iam_policies)

  role = var.worker_iam_role_name

  policy_arn = element(var.additional_concourse_worker_iam_policies, count.index)
}

resource "aws_iam_instance_profile" "concourse_worker" {
  name = var.worker_iam_role_name
  role = var.worker_iam_role_name
}
