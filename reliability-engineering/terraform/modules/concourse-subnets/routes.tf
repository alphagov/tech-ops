data "aws_internet_gateway" "concourse" {
  filter {
    name   = "attachment.vpc-id"
    values = ["${var.vpc_id}"]
  }
}

resource "aws_route_table" "concourse_private" {
  count  = "${var.number_of_availability_zones}"
  vpc_id = "${var.vpc_id}"

  route {
    cidr_block = "0.0.0.0/0"

    nat_gateway_id = "${element(
      aws_nat_gateway.concourse_egress.*.id,
      count.index
    )}"
  }

  tags {
    Name       = "${var.deployment}-${var.name}-private"
    Deployment = "${var.deployment}"
  }
}

resource "aws_route_table_association" "concourse_private" {
  count  = "${var.number_of_availability_zones}"

  subnet_id = "${element(
    aws_subnet.concourse_private.*.id,
    count.index
  )}"

  route_table_id = "${element(
    aws_route_table.concourse_private.*.id,
    count.index
  )}"
}

resource "aws_route_table" "concourse_public" {
  vpc_id = "${var.vpc_id}"

  route {
    cidr_block = "0.0.0.0/0"

    gateway_id = "${data.aws_internet_gateway.concourse.internet_gateway_id}"
  }

  tags {
    Name       = "${var.deployment}-${var.name}-public"
    Deployment = "${var.deployment}"
  }
}

resource "aws_route_table_association" "concourse_public" {
  count  = "${var.number_of_availability_zones}"

  subnet_id = "${element(
    aws_subnet.concourse_public.*.id,
    count.index
  )}"

  route_table_id = "${element(
    aws_route_table.concourse_public.*.id,
    count.index
  )}"
}
