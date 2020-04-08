resource "aws_api_gateway_rest_api" "broker" {
  name = "${var.target_deployment_name}-broker"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = local.service_tags
}

resource "aws_api_gateway_resource" "broker" {
  rest_api_id = aws_api_gateway_rest_api.broker.id
  parent_id   = aws_api_gateway_rest_api.broker.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "broker" {
  rest_api_id   = aws_api_gateway_rest_api.broker.id
  resource_id   = aws_api_gateway_resource.broker.id
  http_method   = "ANY"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "broker" {
  rest_api_id             = aws_api_gateway_rest_api.broker.id
  resource_id             = aws_api_gateway_method.broker.resource_id
  http_method             = aws_api_gateway_method.broker.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.broker.invoke_arn
}

resource "aws_api_gateway_deployment" "broker" {
  rest_api_id = aws_api_gateway_rest_api.broker.id
  stage_name  = "live"
  depends_on = [
    aws_api_gateway_integration.broker,
  ]
}

resource "aws_lambda_permission" "broker" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.broker.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.broker.execution_arn}/*/*"
}

resource "aws_lambda_function" "broker" {
  filename         = var.broker_zip_path
  source_code_hash = filebase64sha256(var.broker_zip_path)
  function_name    = "${var.target_deployment_name}-broker"
  role             = aws_iam_role.broker.arn
  handler          = "broker"
  runtime          = "go1.x"
  memory_size      = 128
  timeout          = 30
  environment {
    variables = {
      CSLS_HMAC_SECRET = random_password.csls_hmac_secret.result,
      CSLS_ADAPTER_URL = "https://${aws_api_gateway_base_path_mapping.adapter.domain_name}",
      BROKER_USERNAME  = var.csls_broker_username,
      BROKER_PASSWORD  = var.csls_broker_password,
    }
  }
  depends_on = [
    aws_iam_role_policy_attachment.broker,
    aws_cloudwatch_log_group.broker,
  ]
  tags = local.service_tags
}

data "aws_iam_policy_document" "broker_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "broker" {
  name               = "${var.target_deployment_name}-broker"
  assume_role_policy = data.aws_iam_policy_document.broker_assume_role.json
  tags               = local.service_tags
}

resource "aws_iam_role_policy_attachment" "broker" {
  role       = aws_iam_role.broker.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "broker" {
  name              = "/aws/lambda/${var.target_deployment_name}-broker"
  retention_in_days = 1
}

resource "aws_acm_certificate" "broker" {
  domain_name       = "${var.target_deployment_name}-broker.${data.aws_route53_zone.main.name}"
  validation_method = "DNS"
}

resource "aws_acm_certificate_validation" "broker" {
  certificate_arn         = aws_acm_certificate.broker.arn
  validation_record_fqdns = [aws_route53_record.broker_cert_validation.fqdn]
}

resource "aws_route53_record" "broker_cert_validation" {
  name    = aws_acm_certificate.broker.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.broker.domain_validation_options.0.resource_record_type
  zone_id = data.aws_route53_zone.main.id
  records = [aws_acm_certificate.broker.domain_validation_options.0.resource_record_value]
  ttl     = 60
}

resource "aws_api_gateway_domain_name" "broker" {
  domain_name              = aws_acm_certificate.broker.domain_name
  regional_certificate_arn = aws_acm_certificate_validation.broker.certificate_arn
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = local.service_tags
  depends_on = [
    aws_acm_certificate_validation.broker,
  ]
}

resource "aws_route53_record" "broker" {
  name    = aws_api_gateway_domain_name.broker.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.main.id
  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.broker.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.broker.regional_zone_id
  }
}

resource "aws_api_gateway_base_path_mapping" "broker" {
  api_id      = aws_api_gateway_rest_api.broker.id
  stage_name  = aws_api_gateway_deployment.broker.stage_name
  domain_name = aws_api_gateway_domain_name.broker.domain_name
}

output "broker_url" {
  value       = "https://${aws_api_gateway_domain_name.broker.domain_name}"
  description = "URL of the broker application to be used as a cloudfoundry service broker"
}


