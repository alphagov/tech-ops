variable "deployment" {
  type = "string"
}

variable "vpc_id" {
  type = "string"
}

variable "public_subnet_ids" {
  type = "list"
}

variable "private_subnet_ids" {
  type = "list"
}

variable "public_root_zone_id" {
  type = "string"
}

variable "private_root_zone_id" {
  type = "string"
}

variable "whitelisted_cidr_blocks" {
  type = "list"
}

variable "main_team_github_team" {
  description = "GitHub Global Admin team $org:$teamName"
  type        = "string"
}

variable "worker_team_names" {
  description = "The names of concourse worker team names, i.e. hosts, for keygen."
  type        = "list"
}

variable "local_user_passwords" {
  description = "The map of team to generated password, used for local users."
  type        = "map"
}

variable "worker_pool_egress_eips" {
  type        = "list"
  description = "A list of all of the egress IPs of all of the worker pools"
}

variable "worker_ssh_public_keys_openssh" {
  type = "map"
}

variable "web_ssh_private_key_pem" {
  type = "string"
}

variable "web_session_private_key_pem" {
  type = "string"
}

variable "web_kms_key_id" {
  type = "string"
}

variable "web_kms_key_arn" {
  type = "string"
}

variable "worker_kms_key_id" {
  type = "string"
}

variable "worker_kms_key_arn" {
  type = "string"
}

variable "web_iam_role_name" {
  type = "string"
}

variable "desired_capacity" {
  default = 1
}

variable "instance_type" {
  default = "t3.small"
}

variable "db_instance_type" {
  default = "db.t2.small"
}

variable "db_storage_gb" {
  default = 100
}

data "aws_caller_identity" "account" {}
