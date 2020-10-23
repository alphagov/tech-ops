variable "deployment" {
  type = string
}

variable "lambda_execution_role_arn" {
  type        = string
  description = "The ARN of an IAM Role to act as execution role for the Lambda that rotates team credentials.  It needs to be trusted to assume the various team roles."
}

variable "lambda_execution_role_name" {
  type        = string
  description = "The name of an IAM Role to act as execution role for the Lambda that rotates team credentials.  It needs to be trusted to assume the various team roles."
}

variable "team_role_arns" {
  type        = map(string)
  description = "A map from team names to IAM Role ARNs representing that team."
}

variable "kms_key_id" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

data "aws_caller_identity" "account" {}
