variable "deployment" {
  type = "string"
}

variable "name" {
  type = "string"
}

variable "subnet_ids" {
  type = "list"
}

variable "security_group_ids" {
  type = "list"
}

variable "private_root_zone_id" {
  type = "string"
}

variable "kms_key_arn" {
  type = "string"
}

variable "desired_capacity" {
  default = 1
}

variable "instance_type" {
  default = "t3.small"
}

variable "additional_concourse_worker_iam_policies" {
  type = "list"
  default = []
}

data "aws_caller_identity" "account" {}
