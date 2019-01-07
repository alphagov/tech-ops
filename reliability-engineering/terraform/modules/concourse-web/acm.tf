resource "aws_acm_certificate" "concourse_public_deployment" {
  domain_name       = "${var.deployment}.${data.aws_route53_zone.public_root.name}"
  validation_method = "DNS"

  tags {
    Deployment = "${var.deployment}"
  }
}

resource "aws_route53_record" "concourse_public_deployment_cert_validation" {
  name    = "${aws_acm_certificate.concourse_public_deployment.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.concourse_public_deployment.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.public_root.zone_id}"

  records = [
    "${aws_acm_certificate.concourse_public_deployment.domain_validation_options.0.resource_record_value}",
  ]

  ttl = 60
}

resource "aws_acm_certificate_validation" "concourse_public_deployment" {
  certificate_arn         = "${aws_acm_certificate.concourse_public_deployment.arn}"
  validation_record_fqdns = ["${aws_route53_record.concourse_public_deployment_cert_validation.fqdn}"]
}
