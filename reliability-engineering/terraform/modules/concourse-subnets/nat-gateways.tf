resource "aws_nat_gateway" "concourse_egress" {
  count = var.number_of_availability_zones

  allocation_id = element(aws_eip.concourse_egress.*.id, count.index)
  subnet_id     = element(aws_subnet.concourse_public.*.id, count.index)

  tags = {
    Name       = "${var.deployment}-${var.name}"
    Deployment = var.deployment
  }
}
