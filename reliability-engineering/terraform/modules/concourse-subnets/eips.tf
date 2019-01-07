resource "aws_eip" "concourse_egress" {
  count = "${var.number_of_availability_zones}"

  tags {
    Name       = "${var.deployment}-${var.name}"
    Deployment = "${var.deployment}"
  }
}

output "concourse_egress_public_ips" {
  value = "${aws_eip.concourse_egress.*.public_ip}"
}
