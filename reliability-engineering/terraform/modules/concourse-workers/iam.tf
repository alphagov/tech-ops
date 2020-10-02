resource "aws_iam_policy" "concourse_worker_base" {
  name = "${var.deployment}-global-concourse-worker-base"

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
          "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.account.account_id}:parameter/${var.deployment}/concourse/worker/global/*"
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
      }
    ]
  }
POLICY
}

resource "aws_iam_role_policy_attachment" "concourse_worker_concourse_worker_base" {
  role       = var.worker_iam_role_name
  policy_arn = aws_iam_policy.concourse_worker_base.arn
}

resource "aws_iam_instance_profile" "concourse_worker" {
  name = var.worker_iam_role_name
  role = var.worker_iam_role_name
}
