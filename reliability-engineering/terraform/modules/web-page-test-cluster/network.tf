# NETWORK TOPOLOGY
#
# 2 public subnets because we need 2 for an Amazon Load Balancer
#
# 1 private subnet for the EC2 instances
#
# NAT gateway so for the instances so they have a known egress IP
# So that we can test private / IP restricted websites

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${element(list("10.0.1.0/24", "10.0.2.0/24"), count.index)}"
  availability_zone = "${element(list("eu-west-1c", "eu-west-1b"), count.index)}"
}

resource "aws_subnet" "private" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.10.0/24"
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "static_ip" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.public.0.id}"
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_route" "public_to_internet" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.main.id}"
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_route" "private_to_nat" {
  route_table_id         = "${aws_route_table.private.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.static_ip.id}"
}

resource "aws_route_table_association" "private" {
  subnet_id      = "${aws_subnet.private.id}"
  route_table_id = "${aws_route_table.private.id}"
}
