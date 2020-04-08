data "cloudfoundry_org" "org" {
  name = var.cf_org
}

data "cloudfoundry_space" "space" {
  name = var.cf_space
  org  = data.cloudfoundry_org.org.id
}

data "cloudfoundry_domain" "cloudapps" {
  name = "cloudapps.digital"
}

resource "cloudfoundry_route" "stub" {
  hostname = "${var.target_deployment_name}-csls-stub"
  domain   = data.cloudfoundry_domain.cloudapps.id
  space    = data.cloudfoundry_space.space.id
}

resource "cloudfoundry_service_broker" "stub" {
  // stub broker is only used for the testing with the stub, it is space-scoped
  name     = "${var.target_deployment_name}-csls-stub"
  url      = "https://${aws_api_gateway_base_path_mapping.broker.domain_name}"
  username = var.csls_broker_username
  password = var.csls_broker_password
  space    = data.cloudfoundry_space.space.id
}

resource "cloudfoundry_service_instance" "stub" {
  name         = "${var.target_deployment_name}-splunk-unlimited"
  space        = data.cloudfoundry_space.space.id
  service_plan = cloudfoundry_service_broker.stub.service_plans["splunk/unlimited"]
  depends_on = [
    cloudfoundry_service_broker.stub,
  ]
}

resource "cloudfoundry_app" "stub" {
  name       = "${var.target_deployment_name}-csls-stub"
  space      = data.cloudfoundry_space.space.id
  path       = var.stub_zip_path
  buildpack  = "binary_buildpack"
  instances  = 1
  disk_quota = 100
  memory     = 64
  command    = "./stub"
  routes {
    route = cloudfoundry_route.stub.id
  }
  service_binding {
    service_instance = cloudfoundry_service_instance.stub.id
  }
}

output "stub_broker_plans" {
  value       = cloudfoundry_service_broker.stub.service_plans
  description = "List of service/plans that were exposed by the space-scoped broker"
}

output "stub_url" {
  value       = "https://${cloudfoundry_route.stub.hostname}.${data.cloudfoundry_domain.cloudapps.name}"
  description = "URL for the log stub application, making requests to this urls triggers logs to be sent to the drain URL"
}
