resource "aws_iam_role" "concourse_worker" {
  name = "${var.deployment}-${var.name}-concourse-worker"

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
          "ssm:DeleteParameter"
        ],
        "Effect": "Allow",
        "Resource": [
          "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.account.account_id}:parameter/${var.deployment}/concourse/pipelines/${var.name}/*"
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

resource "aws_iam_role_policy_attachment" "concourse_worker_concourse_worker_base" {
  role       = "${aws_iam_role.concourse_worker.name}"
  policy_arn = "${aws_iam_policy.concourse_worker_base.arn}"
}

resource "aws_iam_role_policy_attachment" "concourse_worker_additional" {
  count = "${length(var.additional_concourse_worker_iam_policies)}"
  role  = "${aws_iam_role.concourse_worker.name}"

  policy_arn = "${element(
    var.additional_concourse_worker_iam_policies,
    count.index
  )}"
}

resource "aws_iam_instance_profile" "concourse_worker" {
  name = "${aws_iam_role.concourse_worker.name}"
  role = "${aws_iam_role.concourse_worker.name}"
}
