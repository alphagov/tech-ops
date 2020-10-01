data "aws_iam_role" "lambda_execution" {
  name = var.lambda_execution_role_name
}

resource "aws_lambda_function" "sts_creds_to_ssm" {
  filename         = "${path.module}/files/function.zip"
  source_code_hash = filebase64sha256("${path.module}/files/function.zip")
  function_name    = "${var.deployment}_sts_creds_to_ssm"

  role        = data.aws_iam_role.lambda_execution.arn
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
}

resource "aws_cloudwatch_event_rule" "every_ten_minutes" {
  name                = "every-ten-minutes"
  description         = "Fires every 10 minutes"
  schedule_expression = "rate(10 minutes)"
}

resource "aws_cloudwatch_event_target" "update_sts" {
  rule = aws_cloudwatch_event_rule.every_ten_minutes.name
  arn  = aws_lambda_function.sts_creds_to_ssm.arn

  for_each = var.team_role_arns

  target_id = each.key
  input = jsonencode({
    team_name = each.key
    role_arn  = each.value
  })
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_sts_creds_to_ssm" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sts_creds_to_ssm.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_ten_minutes.arn
}

resource "aws_cloudwatch_log_group" "sts_lambda" {
  name              = "/aws/lambda/${aws_lambda_function.sts_creds_to_ssm.function_name}"
  retention_in_days = 7
}
