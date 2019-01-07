resource "aws_iam_role" "concourse_prometheus" {
  name = "${var.deployment}-concourse-prometheus"

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

resource "aws_iam_policy" "concourse_prometheus" {
  name = "${var.deployment}-concourse-prometheus"

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
      },
      {
        "Effect" : "Allow",
        "Action" : "ec2:DescribeInstances",
        "Resource" : "*"
      }
    ]
  }
  POLICY
}

resource "aws_iam_role_policy_attachment" "concourse_prometheus_concourse_prometheus" {
  role       = "${aws_iam_role.concourse_prometheus.name}"
  policy_arn = "${aws_iam_policy.concourse_prometheus.arn}"
}

resource "aws_iam_instance_profile" "concourse_prometheus" {
  name = "${aws_iam_role.concourse_prometheus.name}"
  role = "${aws_iam_role.concourse_prometheus.name}"
}

resource "aws_iam_role" "concourse_grafana" {
  name = "${var.deployment}-concourse-grafana"

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

resource "aws_iam_policy" "concourse_grafana" {
  name = "${var.deployment}-concourse-grafana"

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
        "Effect": "Allow",
        "Action": [
          "s3:GetEncryptionConfiguration",
          "ecs:DiscoverPollEndpoint",
          "ecs:StartTelemetrySession",
          "ecs:Poll",
          "ecs:Submit*"
        ],
        "Resource": "*"
      }, {
        "Effect": "Allow",
        "Action": [
          "ecs:RegisterContainerInstance",
          "ecs:DeregisterContainerInstance"
        ],
        "Resource": [
          "arn:aws:ecs:eu-west-2:${data.aws_caller_identity.account.account_id}:cluster/${var.deployment}-grafana"
        ]
      }
    ]
  }
  POLICY
}

resource "aws_iam_role_policy_attachment" "concourse_grafana_concourse_grafana" {
  role       = "${aws_iam_role.concourse_grafana.name}"
  policy_arn = "${aws_iam_policy.concourse_grafana.arn}"
}

resource "aws_iam_instance_profile" "concourse_grafana" {
  name = "${aws_iam_role.concourse_grafana.name}"
  role = "${aws_iam_role.concourse_grafana.name}"
}

resource "aws_iam_role" "concourse_grafana_execution" {
  name = "${var.deployment}-concourse-grafana-execution"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF
}

resource "aws_iam_policy" "concourse_grafana_execution" {
  name = "${var.deployment}-concourse-grafana-execution"

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        "Resource": [
          "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.account.account_id}:parameter/${var.deployment}/grafana/*"
        ]
      }, {
        "Effect": "Allow",
        "Action": [
          "kms:ListKeys",
          "kms:ListAliases",
          "kms:Describe*",
          "kms:Decrypt"
        ],
        "Resource": "${aws_kms_key.concourse_grafana.arn}"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "concourse_grafana_execution_concourse_grafana_execution" {
  role       = "${aws_iam_role.concourse_grafana_execution.name}"
  policy_arn = "${aws_iam_policy.concourse_grafana_execution.arn}"
}
