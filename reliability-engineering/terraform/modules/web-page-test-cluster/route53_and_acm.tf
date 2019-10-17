data "aws_route53_zone" "zone" {
  name = "${var.domain}."
}

resource "aws_acm_certificate" "domain" {
  domain_name               = "${var.subdomain}.${var.domain}"
  validation_method         = "DNS"
}

resource "aws_route53_record" "domain_validation" {
  name    = "${aws_acm_certificate.domain.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.domain.domain_validation_options.0.resource_record_type}"
  records = ["${aws_acm_certificate.domain.domain_validation_options.0.resource_record_value}"]

  zone_id = "${data.aws_route53_zone.zone.id}"
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = "${aws_acm_certificate.domain.arn}"
  validation_record_fqdns = ["${aws_route53_record.domain_validation.fqdn}"]
}
