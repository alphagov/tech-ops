data "template_file" "event_pattern" {
  template = file("${path.module}/json/cloudwatch_event_pattern.tmpl")
  vars {
    target_arn = var.bucket_arn_list
  }
}

resource "aws_cloudwatch_event_rule" "s3_events" {
  name        = local.cloudwatch_event_rule_name
  description = "S3 object level logging rule"

  tags = merge(local.tags, map("Name", local.cloudwatch_event_rule_name))

  event_pattern = data.template_file.event_pattern.rendered
}

resource "aws_cloudwatch_event_target" "cloudwatch_target" {
  rule      = aws_cloudwatch_event_rule.s3_events.name
  target_id = "S3EventsLogGroup"
  arn       = substr(aws_cloudwatch_log_group.s3_events_log_group.arn, 0, length(aws_cloudwatch_log_group.s3_events_log_group.arn) - 2)
}

resource "aws_cloudwatch_log_group" "s3_events_log_group" {
  name = local.cloudwatch_log_group_name

  tags = merge(local.tags, map("Name", local.cloudwatch_log_group_name))
}

resource "aws_cloudwatch_log_subscription_filter" "log_subscription" {
  name            = "csls_s3_object_logging_cloudwatch_log_subscription"
  log_group_name  = local.cloudwatch_log_group_name
  filter_pattern  = var.cloudwatch_filter_pattern
  destination_arn = var.cloudwatch_destination_arn
}
