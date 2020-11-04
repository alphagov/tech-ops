terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    grafana = {
      source = "grafana/grafana"
    }
    random = {
      source = "hashicorp/random"
    }
    template = {
      source = "hashicorp/template"
    }
  }
  required_version = ">= 0.13"
}

