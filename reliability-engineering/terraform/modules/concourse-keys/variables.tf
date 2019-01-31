variable "deployment" {
  type = "string"
}

variable "worker_team_names" {
  description = "The names of concourse worker team names, i.e. hosts, for keygen."
  type        = "list"
}

data "aws_caller_identity" "account" {}
