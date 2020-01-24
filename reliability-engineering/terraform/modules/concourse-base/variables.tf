variable "deployment" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "ingress_subnet_cidrs" {
  type = list(string)
}

variable "number_of_availability_zones" {
  default = 2
}

data "aws_availability_zones" "available" {}

locals {
  availability_zone_names = slice(
    data.aws_availability_zones.available.names,
    0,
    var.number_of_availability_zones,
  )

  availability_zone_ids = slice(
    data.aws_availability_zones.available.zone_ids,
    0,
    var.number_of_availability_zones,
  )
}
