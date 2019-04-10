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

variable "web_ssh_public_key_openssh" {
  type = "string"
}

variable "worker_ssh_private_key_pem" {
  type = "string"
}

variable "kms_key_id" {
  type = "string"
}

variable "kms_key_arn" {
  type = "string"
}

variable "worker_iam_role_name" {
  type = "string"
}

variable "desired_capacity" {
  default = 1
}

variable "instance_type" {
  default = "t3.small"
}

variable "volume_size" {
  default = 50
}

variable "additional_concourse_worker_iam_policies" {
  type    = "list"
  default = []
}

data "aws_caller_identity" "account" {}
