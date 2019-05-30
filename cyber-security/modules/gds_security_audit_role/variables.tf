# This should be left to default to an empty string outside the Cyber Security team
variable "prefix" {
  default = ""
}

# This is the AWS account ID for the billing account.
# Ask tech-ops if you're unsure.
variable "chain_account_id" {}
