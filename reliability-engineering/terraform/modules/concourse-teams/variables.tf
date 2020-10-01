variable "deployment" {
  type = string
}

variable "team_names" {
  description = "The names of concourse teams."
  type        = list(string)
}

variable "kms_key_id" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

data "aws_caller_identity" "account" {}
