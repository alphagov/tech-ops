resource "aws_nat_gateway" "concourse_egress" {
  count = var.number_of_availability_zones

  allocation_id = aws_eip.concourse_egress[count.index].id
  subnet_id     = aws_subnet.concourse_public[count.index].id

  tags = {
    Name       = "${var.deployment}-${var.name}"
    Deployment = var.deployment
  }
}
