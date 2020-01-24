resource "aws_subnet" "concourse_private" {
  count = var.number_of_availability_zones

  availability_zone = local.availability_zone_names[count.index]

  vpc_id     = var.vpc_id
  cidr_block = var.private_subnet_cidrs[count.index]

  tags = {
    Name       = "${var.deployment}-${var.name}-private"
    Deployment = var.deployment
  }
}

# Only the NAT gateways go in here
resource "aws_subnet" "concourse_public" {
  count = var.number_of_availability_zones

  vpc_id     = var.vpc_id
  cidr_block = var.public_subnet_cidrs[count.index]

  tags = {
    Name       = "${var.deployment}-${var.name}-public"
    Deployment = var.deployment
  }
}

# Only the private ones should be used externally
output "concourse_subnet_ids" {
  value = aws_subnet.concourse_private.*.id
}
