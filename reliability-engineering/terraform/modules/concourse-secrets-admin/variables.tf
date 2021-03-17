data "aws_caller_identity" "account" {}

variable "deployment" {
  type = string
}

variable "concourse_team_name" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "oidc_host_path" {
  type = string
}

variable "github_oauth_client_id" {
  type = string
}

variable "trusted_github_team_id" {
  type = string
}
