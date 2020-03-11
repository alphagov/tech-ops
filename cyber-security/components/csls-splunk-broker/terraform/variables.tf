
locals {
  service_tags = {
    Service       = "csls-splunk-adapter",
    Environment   = var.target_deployment_name,
    SvcOwner      = "cyber-security",
    DeployedUsing = "https://cd.gds-reliability.engineering/teams/cybersecurity-tools/pipelines/csls-splunk-broker",
    SvcCodeURL    = "https://github.com/alphagov/tech-ops/tree/master/cyber-security/components/csls-splunk-broker"
  }
}

variable "target_deployment_name" {
  type        = string
  default     = "test"
  description = "Deployment environment/name used to prefix resources to avoid clashes"
}

variable "target_deployer_role_arn" {
  type        = string
  description = "ARN of the deployment role in target account where we will provision things"
}

variable "target_zone_name" {
  description = "domain name of zone delegated in target account"
  default     = "staging.gds-cyber-security.digital."
}

variable "csls_deployer_role_arn" {
  type        = string
  description = "ARN of the deployment role in csls account where the stream lives"
}

variable "cf_username" {
  type = string
}

variable "cf_password" {
  type = string
}

variable "cf_org" {
  type = string
}

variable "cf_space" {
  type = string
}

variable "csls_stream_name" {
  type = string
}

variable "csls_broker_username" {
  type = string
}

variable "csls_broker_password" {
  type = string
}

variable "adapter_zip_path" {
  type        = string
  description = "path to a zip of the compiled adapter application"
}

variable "broker_zip_path" {
  type        = string
  description = "path to a zip of the compiled broker application"
}

variable "stub_zip_path" {
  type        = string
  description = "path to a zip of the compiled stub application"
}
