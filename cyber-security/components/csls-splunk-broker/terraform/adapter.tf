resource "aws_api_gateway_rest_api" "adapter" {
  name = "${var.target_deployment_name}-adapter"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = local.service_tags
}

resource "aws_api_gateway_method" "adapter" {
  rest_api_id   = aws_api_gateway_rest_api.adapter.id
  resource_id   = aws_api_gateway_rest_api.adapter.root_resource_id
  http_method   = "POST"
  authorization = "NONE"
  request_parameters = {
    "method.request.querystring.app_guid" = true
    "method.request.querystring.mac"      = true
  }
}

resource "aws_api_gateway_integration" "adapter" {
  rest_api_id             = aws_api_gateway_rest_api.adapter.id
  resource_id             = aws_api_gateway_method.adapter.resource_id
  http_method             = aws_api_gateway_method.adapter.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.adapter.invoke_arn
}

resource "aws_api_gateway_deployment" "adapter" {
  rest_api_id = aws_api_gateway_rest_api.adapter.id
  stage_name  = "live"
  depends_on = [
    aws_api_gateway_integration.adapter,
  ]
}

resource "aws_lambda_permission" "adapter" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.adapter.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.adapter.execution_arn}/*/*"
}

resource "aws_lambda_function" "adapter" {
  filename         = var.adapter_zip_path
  source_code_hash = filebase64sha256(var.adapter_zip_path)
  function_name    = "${var.target_deployment_name}-adapter"
  role             = aws_iam_role.adapter.arn
  handler          = "adapter"
  runtime          = "go1.x"
  memory_size      = 128
  timeout          = 30

  environment {
    variables = {
      CSLS_STREAM_NAME = var.csls_stream_name,
      CSLS_HMAC_SECRET = random_password.csls_hmac_secret.result,
      CSLS_ROLE_ARN    = aws_iam_role.csls.arn,
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.adapter_basic,
    aws_cloudwatch_log_group.adapter,
  ]

  tags = local.service_tags
}

data "aws_iam_policy_document" "adapter_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "adapter" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "adapter" {
  name               = "${var.target_deployment_name}-adapter"
  assume_role_policy = data.aws_iam_policy_document.adapter_assume_role.json
  tags               = local.service_tags
}

resource "aws_iam_policy" "adapter" {
  name   = "${var.target_deployment_name}-adapter"
  policy = data.aws_iam_policy_document.adapter.json
}

resource "aws_iam_role_policy_attachment" "adapter" {
  role       = aws_iam_role.adapter.name
  policy_arn = aws_iam_policy.adapter.arn
}

resource "aws_iam_role_policy_attachment" "adapter_basic" {
  role       = aws_iam_role.adapter.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "adapter" {
  name              = "/aws/lambda/${var.target_deployment_name}-adapter"
  retention_in_days = 1
}

resource "aws_acm_certificate" "adapter" {
  domain_name       = "${var.target_deployment_name}-adapter.${data.aws_route53_zone.main.name}"
  validation_method = "DNS"
}

resource "aws_acm_certificate_validation" "adapter" {
  certificate_arn         = aws_acm_certificate.adapter.arn
  validation_record_fqdns = [aws_route53_record.adapter_cert_validation.fqdn]
}

resource "aws_route53_record" "adapter_cert_validation" {
  name    = aws_acm_certificate.adapter.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.adapter.domain_validation_options.0.resource_record_type
  zone_id = data.aws_route53_zone.main.id
  records = [aws_acm_certificate.adapter.domain_validation_options.0.resource_record_value]
  ttl     = 60
}

resource "aws_api_gateway_domain_name" "adapter" {
  domain_name              = aws_acm_certificate.adapter.domain_name
  regional_certificate_arn = aws_acm_certificate_validation.adapter.certificate_arn
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  tags = local.service_tags
  depends_on = [
    aws_acm_certificate_validation.adapter,
  ]
}

resource "aws_route53_record" "adapter" {
  name    = aws_api_gateway_domain_name.adapter.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.main.id
  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.adapter.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.adapter.regional_zone_id
  }
}

resource "aws_api_gateway_base_path_mapping" "adapter" {
  api_id      = aws_api_gateway_rest_api.adapter.id
  stage_name  = aws_api_gateway_deployment.adapter.stage_name
  domain_name = aws_api_gateway_domain_name.adapter.domain_name
}

output "adapter_url" {
  value       = "https://${aws_api_gateway_domain_name.adapter.domain_name}"
  description = "URL of the adapter application to be used as a cloudfoundry syslog drain"
}
