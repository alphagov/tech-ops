resource "aws_subnet" "concourse_ingress" {
  count = "${var.number_of_availability_zones}"

  availability_zone = "${element(
    local.availability_zone_names,
    count.index
  )}"

  vpc_id     = "${aws_vpc.concourse.id}"
  cidr_block = "${element(var.ingress_subnet_cidrs, count.index)}"

  tags {
    Name       = "${var.deployment}-ingress"
    Deployment = "${var.deployment}"
  }
}

resource "aws_route_table" "concourse_ingress" {
  vpc_id = "${aws_vpc.concourse.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.concourse.id}"
  }

  tags {
    Name       = "${var.deployment}-public"
    Deployment = "${var.deployment}"
  }
}

resource "aws_route_table_association" "concourse_ingress" {
  count = "${var.number_of_availability_zones}"

  subnet_id      = "${element(aws_subnet.concourse_ingress.*.id, count.index)}"
  route_table_id = "${aws_route_table.concourse_ingress.id}"
}

output "concourse_ingress_subnet_ids" {
  value = "${aws_subnet.concourse_ingress.*.id}"
}
