variable "env" {
  type    = "string"
  default = "web-page-test"
}

variable "ingress_cidrs" {
  type = "list"
  default = ["0.0.0.0/0"]
}

variable "domain" {}
variable "subdomain" {}

variable "bucket_name" {}

variable "google_oauth_client_id" {}
variable "google_oauth_client_secret" {}
