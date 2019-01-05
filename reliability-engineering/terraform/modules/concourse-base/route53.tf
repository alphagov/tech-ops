resource "aws_route53_zone" "concourse_internal" {
  name = "concourse.internal"

  vpc {
    vpc_id = "${aws_vpc.concourse.id}"
  }

  tags = {
    Deployment = "${var.deployment}"
  }
}

output "concourse_internal_zone_id" {
  value = "${aws_route53_zone.concourse_internal.zone_id}"
}
