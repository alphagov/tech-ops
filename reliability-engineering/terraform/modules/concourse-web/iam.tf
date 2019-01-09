resource "aws_iam_role" "concourse_web" {
  name = "${var.deployment}-concourse-web"

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
      }
    ]
  }
  ARP
}

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
          "${aws_kms_key.concourse_web.arn}",
          "${aws_kms_key.concourse_worker_shared.arn}"
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
      }
    ]
  }
  POLICY
}

resource "aws_iam_role_policy_attachment" "concourse_web_concourse_web" {
  role       = "${aws_iam_role.concourse_web.name}"
  policy_arn = "${aws_iam_policy.concourse_web.arn}"
}

resource "aws_iam_instance_profile" "concourse_web" {
  name = "${aws_iam_role.concourse_web.name}"
  role = "${aws_iam_role.concourse_web.name}"
}
