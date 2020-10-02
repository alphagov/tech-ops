variable "deployment" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "private_root_zone_id" {
  type = string
}

variable "web_ssh_public_key_openssh" {
  type = string
}

variable "worker_ssh_private_key_pem" {
  type = string
}

variable "kms_key_id" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "worker_iam_role_name" {
  type = string
}

variable "desired_capacity" {
  default = 1
}

variable "on_demand_percentage" {
  default     = 100
  description = "Percentage of instances to be launched as on-demand (ie not spot)"
}

variable "instance_type" {
  default = "t3.small"
}

variable "spot_instance_types" {
  type        = list(string)
  default     = []
  description = "Instance types available for use as spot instances"
}

variable "volume_size" {
  default = 50
}

variable "concourse_version" {
  type = string
}

variable "concourse_sha1" {
  type = string
}

data "aws_caller_identity" "account" {}

