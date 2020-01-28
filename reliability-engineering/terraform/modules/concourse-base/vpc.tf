resource "aws_vpc" "concourse" {
  cidr_block = var.vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name       = "${var.deployment}-concourse"
    Deployment = var.deployment
  }
}

resource "aws_internet_gateway" "concourse" {
  vpc_id = aws_vpc.concourse.id

  tags = {
    Name       = "${var.deployment}-concourse"
    Deployment = var.deployment
  }
}

output "concourse_vpc_id" {
  value = aws_vpc.concourse.id
}
