data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "prometheus_execution" {
  name               = "${var.deployment}-prometheus-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

data "aws_iam_policy_document" "prometheus_data_volume_access" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.concourse_prometheus.arn]
    }

    actions = [
      "elasticfilesystem:DescribeFileSystemPolicy",
      "elasticfilesystem:PutFileSystemPolicy",
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
    ]

    condition {
      test     = "StringEquals"
      variable = "elasticfilesystem:AccessPointArn"
      values   = [aws_efs_access_point.prometheus.arn]
    }

    resources = [aws_efs_file_system.prometheus.arn]
  }
}

data "aws_iam_policy_document" "prometheus_cloudwatch_access" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      aws_cloudwatch_log_group.prometheus.arn,
      "${aws_cloudwatch_log_group.prometheus.arn}:log-stream:*",
    ]
  }
}

resource "aws_iam_policy" "prometheus_cloudwatch_access" {
  name   = "${var.deployment}-prometheus-cloudwatch-access"
  policy = data.aws_iam_policy_document.prometheus_cloudwatch_access.json
}

resource "aws_iam_role_policy_attachment" "prometheus_cloudwatch_access" {
  role       = aws_iam_role.prometheus_execution.name
  policy_arn = aws_iam_policy.prometheus_cloudwatch_access.arn
}
