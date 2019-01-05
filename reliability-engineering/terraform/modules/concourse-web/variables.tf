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
