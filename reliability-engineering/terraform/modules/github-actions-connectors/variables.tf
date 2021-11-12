
variable "zendesk_scripts_output_bucket" {
  description = "This is a s3 bucket the zendesk tickets output to" 
}

variable "github_oidc_claim" {
  description = "The OIDC Claim for the repo"
  default = "environment:development"  
}

variable "deployment" {
  type = string
}