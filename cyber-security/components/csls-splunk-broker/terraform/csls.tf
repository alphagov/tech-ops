data "aws_caller_identity" "csls" {
  provider = aws.csls
}

data "aws_iam_policy_document" "csls_permissions" {
  provider = aws.csls
  statement {
    effect = "Allow"
    actions = [
      "kinesis:DescribeStream",
      "kinesis:GetShardIterator",
      "kinesis:ListStreams",
      "kinesis:PutRecords",
      "kinesis:PutRecord",
    ]
    resources = ["arn:aws:kinesis:eu-west-2:${data.aws_caller_identity.csls.account_id}:stream/${var.csls_stream_name}"]
  }
}

resource "aws_iam_policy" "csls_permissions" {
  provider = aws.csls
  name     = "${var.target_deployment_name}-syslog-http-adapter"
  policy   = data.aws_iam_policy_document.csls_permissions.json
}

data "aws_iam_policy_document" "csls_assume_role" {
  provider = aws.csls
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.adapter.arn]
    }
  }
}

resource "aws_iam_role" "csls" {
  provider           = aws.csls
  name               = "${var.target_deployment_name}-syslog-http-adapter"
  assume_role_policy = data.aws_iam_policy_document.csls_assume_role.json
  tags               = local.service_tags
}

resource "aws_iam_role_policy_attachment" "csls_permissions" {
  provider   = aws.csls
  role       = aws_iam_role.csls.name
  policy_arn = aws_iam_policy.csls_permissions.arn
}
