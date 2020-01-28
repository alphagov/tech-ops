data "aws_vpc" "concourse" {
  id = var.vpc_id
}

locals {
  vpc_dns_resolver = cidrhost(data.aws_vpc.concourse.cidr_block, 2)
}
