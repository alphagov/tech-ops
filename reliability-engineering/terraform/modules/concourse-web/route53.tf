data "aws_route53_zone" "public_root" {
  zone_id = var.public_root_zone_id
}

data "aws_route53_zone" "private_root" {
  zone_id = var.private_root_zone_id
}

resource "aws_route53_record" "concourse_public_deployment" {
  zone_id = data.aws_route53_zone.public_root.zone_id
  name    = "${var.deployment}.${data.aws_route53_zone.public_root.name}"
  type    = "A"

  alias {
    name                   = aws_lb.concourse_web.dns_name
    zone_id                = aws_lb.concourse_web.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "concourse_private_web" {
  zone_id = data.aws_route53_zone.private_root.zone_id
  name    = "web.${data.aws_route53_zone.private_root.name}"
  type    = "A"

  alias {
    name                   = aws_elb.concourse_web.dns_name
    zone_id                = aws_elb.concourse_web.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "concourse_private_db" {
  zone_id = data.aws_route53_zone.private_root.zone_id
  name    = "db.${data.aws_route53_zone.private_root.name}"
  type    = "A"

  alias {
    name                   = aws_db_instance.concourse.address
    zone_id                = aws_db_instance.concourse.hosted_zone_id
    evaluate_target_health = false
  }
}
