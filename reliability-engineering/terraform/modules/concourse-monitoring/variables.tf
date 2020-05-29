variable "deployment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "main_nat_gateway_egress_ips" {
  type = list(string)
}

variable "prometheus_security_group_id" {
  type = string
}

variable "public_root_zone_id" {
  type = string
}

variable "private_root_zone_id" {
  type = string
}

variable "whitelisted_cidr_blocks" {
  type = list(string)
}

variable "grafana_github_allowed_organizations" {
  type = list(string)
}

variable "prometheus_instance_type" {
  default = "t3.small"
}

variable "grafana_instance_type" {
  default = "t3.small"
}

data "aws_caller_identity" "account" {}

variable "prometheus_volume_size" {
  default = 100
}
