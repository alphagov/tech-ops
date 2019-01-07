locals {
  monitoring_domain = "monitoring.${var.deployment}.${data.aws_route53_zone.public_root.name}"
}

resource "aws_acm_certificate" "concourse_monitoring" {
  domain_name               = "${local.monitoring_domain}"
  subject_alternative_names = ["*.${local.monitoring_domain}"]
  validation_method         = "DNS"

  tags {
    Deployment = "${var.deployment}"
  }
}

resource "aws_route53_record" "concourse_monitoring_cert_validation" {
  name    = "${aws_acm_certificate.concourse_monitoring.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.concourse_monitoring.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.public_root.zone_id}"

  records = [
    "${aws_acm_certificate.concourse_monitoring.domain_validation_options.0.resource_record_value}",
  ]

  ttl = 60
}

resource "aws_acm_certificate_validation" "concourse_web" {
  certificate_arn         = "${aws_acm_certificate.concourse_monitoring.arn}"
  validation_record_fqdns = ["${aws_route53_record.concourse_monitoring_cert_validation.fqdn}"]
}
