resource "aws_acm_certificate" "concourse_public_deployment" {
  domain_name       = "${var.deployment}.${data.aws_route53_zone.public_root.name}"
  validation_method = "DNS"

  tags = {
    Deployment = var.deployment
  }
}

resource "aws_route53_record" "concourse_public_deployment_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.concourse_public_deployment.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name    = each.value.name
  records = [each.value.record]
  type    = each.value.type
  zone_id = data.aws_route53_zone.public_root.zone_id
  ttl     = 60
}

resource "aws_acm_certificate_validation" "concourse_public_deployment" {
  certificate_arn         = aws_acm_certificate.concourse_public_deployment.arn
  validation_record_fqdns = [aws_route53_record.concourse_public_deployment_cert_validation.fqdn]
}
