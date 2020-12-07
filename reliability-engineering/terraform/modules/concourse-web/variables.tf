variable "deployment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
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

variable "main_team_github_team" {
  description = "GitHub Global Admin team $org:$teamName"
  type        = string
}

variable "worker_team_names" {
  description = "The names of concourse worker team names, i.e. hosts, for keygen."
  type        = list(string)
}

variable "local_user_passwords" {
  description = "The map of team to generated password, used for local users."
  type        = map(string)
}

variable "worker_pool_egress_eips" {
  type        = list(string)
  description = "A list of all of the egress IPs of all of the worker pools"
}

variable "worker_ssh_public_keys_openssh" {
  type        = map(string)
  description = "A map from team names to authorized_keys content for workers pinned to a specific team."
}

variable "web_ssh_private_key_pem" {
  type = string
}

variable "web_session_private_key_pem" {
  type = string
}

variable "web_kms_key_id" {
  type = string
}

variable "web_kms_key_arn" {
  type = string
}

variable "worker_kms_key_id" {
  type = string
}

variable "worker_kms_key_arn" {
  type = string
}

variable "web_iam_role_name" {
  type = string
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

variable "db_performance_insights_enabled" {
  default = false
}

variable "db_multi_az" {
  default = false
}

variable "db_backup_retention_period" {
  default = 0
}

variable "concourse_version" {
  type = string
}

variable "concourse_sha1" {
  type = string
}

data "aws_caller_identity" "account" {}

locals {
  concourse_web_syslog_log_group_name = "/${var.deployment}/concourse/web"
}
