data "aws_route53_zone" "public_root" {
  zone_id = var.public_root_zone_id
}

data "aws_route53_zone" "private_root" {
  zone_id = var.private_root_zone_id
}

resource "aws_route53_record" "concourse_public_prometheis" {
  count   = 2
  zone_id = data.aws_route53_zone.public_root.zone_id
  name    = "prom-${count.index + 1}.${local.monitoring_domain}"
  type    = "A"

  alias {
    name                   = aws_lb.concourse_monitoring.dns_name
    zone_id                = aws_lb.concourse_monitoring.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "concourse_public_grafana" {
  zone_id = data.aws_route53_zone.public_root.zone_id
  name    = "grafana.${local.monitoring_domain}"
  type    = "A"

  alias {
    name                   = aws_lb.concourse_monitoring.dns_name
    zone_id                = aws_lb.concourse_monitoring.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "concourse_private_prometheus" {
  zone_id = data.aws_route53_zone.private_root.zone_id
  name    = "prometheus.${data.aws_route53_zone.private_root.name}"
  type    = "A"
  ttl     = 10
  records = aws_instance.concourse_prometheus.*.private_ip
}

resource "aws_route53_record" "concourse_private_prometheis" {
  count   = 2
  zone_id = data.aws_route53_zone.private_root.zone_id
  name    = "prom-${count.index + 1}.${data.aws_route53_zone.private_root.name}"
  type    = "A"
  ttl     = 10

  records = [
    aws_instance.concourse_prometheus[count.index].private_ip,
  ]
}

locals {
  grafana_url = "https://${aws_route53_record.concourse_public_grafana.fqdn}"
}
