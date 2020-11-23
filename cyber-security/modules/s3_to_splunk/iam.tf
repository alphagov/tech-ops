data "aws_iam_policy_document" "cloudwatch_event_logging_policy_doc" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:eu-west-2:${data.aws_caller_identity.current.account_id}:log-group:${local.cloudwatch_log_group_name}:*"]

    principals {
      identifiers = ["delivery.logs.amazonaws.com", "events.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "cloudwatch_event_logging_policy" {
  policy_document = data.aws_iam_policy_document.cloudwatch_event_logging_policy_doc.json
  policy_name     = "TrustEventsToStoreLogEvents"
}
