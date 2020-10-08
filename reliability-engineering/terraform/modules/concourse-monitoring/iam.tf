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
  role       = aws_iam_role.concourse_prometheus.name
  policy_arn = aws_iam_policy.concourse_prometheus.arn
}

resource "aws_iam_instance_profile" "concourse_prometheus" {
  name = aws_iam_role.concourse_prometheus.name
  role = aws_iam_role.concourse_prometheus.name
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
      }, {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents"
        ],
        "Resource": "*"
      }
    ]
  }
EOF
}

resource "aws_iam_role_policy_attachment" "concourse_grafana_execution_concourse_grafana_execution" {
  role       = aws_iam_role.concourse_grafana_execution.name
  policy_arn = aws_iam_policy.concourse_grafana_execution.arn
}

resource "aws_iam_role" "concourse_grafana_task" {
  name = "${var.deployment}-concourse-grafana-task"

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

resource "aws_iam_policy" "concourse_grafana_task" {
  name = "${var.deployment}-concourse-grafana-task"

  # policy pulled verbatim from
  # https://grafana.com/docs/grafana/latest/features/datasources/cloudwatch/
  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AllowReadingMetricsFromCloudWatch",
        "Effect": "Allow",
        "Action": [
          "cloudwatch:DescribeAlarmsForMetric",
          "cloudwatch:DescribeAlarmHistory",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricData"
        ],
        "Resource": "*"
      },
      {
        "Sid": "AllowReadingLogsFromCloudWatch",
        "Effect": "Allow",
        "Action": [
          "logs:DescribeLogGroups",
          "logs:GetLogGroupFields",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:GetQueryResults",
          "logs:GetLogEvents"
        ],
        "Resource": "*"
      },
      {
        "Sid": "AllowReadingTagsInstancesRegionsFromEC2",
        "Effect": "Allow",
        "Action": ["ec2:DescribeTags", "ec2:DescribeInstances", "ec2:DescribeRegions"],
        "Resource": "*"
      },
      {
        "Sid": "AllowReadingResourcesForTags",
        "Effect": "Allow",
        "Action": "tag:GetResources",
        "Resource": "*"
      }
    ]
  }
EOF
}

resource "aws_iam_role_policy_attachment" "concourse_grafana_task_concourse_grafana_task" {
  role       = aws_iam_role.concourse_grafana_task.name
  policy_arn = aws_iam_policy.concourse_grafana_task.arn
}
