data "archive_file" "sts_lambda_function_py" {
  type        = "zip"
  output_path = "${path.module}/files/lambda_rotate_sts.zip"

  source {
    content  = file("${path.module}/files/lambda_rotate_sts.py")
    filename = "lambda_function.py"
  }
}

locals {
  function_name = "${var.deployment}_sts_creds_to_ssm"
}

resource "aws_lambda_function" "sts_creds_to_ssm" {
  filename         = data.archive_file.sts_lambda_function_py.output_path
  source_code_hash = data.archive_file.sts_lambda_function_py.output_base64sha256
  function_name    = local.function_name

  role        = var.lambda_execution_role_arn
  handler     = "lambda_function.lambda_handler"
  runtime     = "python3.7"
  timeout     = "240"
  memory_size = "128"
  description = "Assumes a given role and puts the resulting STS credentials into parameter store for concourse teams to use"

  kms_key_arn = var.kms_key_arn
  environment {
    variables = {
      DEPLOYMENT = var.deployment
      KEY_ID     = var.kms_key_id
    }
  }

  depends_on = [aws_cloudwatch_log_group.sts_lambda]
}

resource "aws_cloudwatch_event_rule" "every_ten_minutes" {
  name                = "${var.deployment}-every-ten-minutes-${each.key}"
  description         = "Fires every 10 minutes"
  schedule_expression = "rate(10 minutes)"

  for_each = var.team_role_arns
}

resource "aws_cloudwatch_event_target" "update_sts" {
  rule = aws_cloudwatch_event_rule.every_ten_minutes[each.key].name
  arn  = aws_lambda_function.sts_creds_to_ssm.arn

  for_each = var.team_role_arns

  target_id = each.key
  input = jsonencode({
    team_name = each.key
    role_arn  = each.value
  })
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_sts_creds_to_ssm" {
  statement_id  = "AllowExecutionFromCloudWatch${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sts_creds_to_ssm.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_ten_minutes[each.key].arn

  for_each = var.team_role_arns
}

resource "aws_cloudwatch_log_group" "sts_lambda" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 7
}
