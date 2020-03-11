# csls-splunk-broker

## Overview

csls-splunk-broker allows GOV.UK PaaS tenants to ship/store their application logs
in Splunk managed by the GDS Cyber Security Team.

## Components

### Broker

The `broker` implements the Open Service Broker API and provides the integration between
a cloudfoundry instance and the CSLS system. It's job is to enable tenants to
turn on log shipping by issing `cf create-service` and `cf bind-service`
commands.

For more information see: [./cmd/broker][broker]

### Adapter

The `adapater` accepts "syslog over http" traffic, verifies that the log
messages are from a authorized source and forwards them on to the CSLS system
(AWS Kinesis). It's job is to convert cloudfoundry format logs into CSLS format logs.

For more information see: [./cmd/adapter][adapter]

### Stub

The `stub` is dummy application deployable to cloudfoundry that is used in the
end to end tests. It's job is to emit log traffic on demand with a UUID so that it
can be traced through the system.

For more information see: [./cmd/stub][stub]

## Deployment

Changes to this repository (including to the pipeline itself) are continuously
deployed by a pipeline in the [cybersecurity-tools concourse][pipeline]

You shouldn't need to, but you can manually set the deployment pipeline using fly:

```
fly -t cd-cybersecurity-tools set-pipeline \
	-p csls-splunk-broker \
	-c ./ci/pipeline.yml
```

The deployment is managed by terraform and configuration for it all can be
found in the [terraform directory][terraform]

* The `broker` is deployed as a Lambda
* The `adapter` is deployed as a Lambda
* The `stub` is deployed as cloudfoundry application

The pipeline builds the applications, provisions a staging instance of the
system to the `security-test` account, runs the e2e test against it, then
deploys into the `security-cls` account if test deployment went ok.

## Testing

### Unit Tests

Unit tests for the codebase can be executed with the standard Go toolchain:

```
go test ./...
```

### End-to-End Tests

The e2e tests work by:

* creating a space-scoped version of the broker in GOV.UK PaaS
* deploying the an instance of the `stub` application to GOV.UK PaaS
* creating a service instance from the space-scoped broker
* binding the `stub` to the space-scoped service instance
* making an request to the `stub` application (triggering it to generate some logs)
* using the `splunk-query` script to poll splunk until the expected logs appear

The terraform that deploys all this can be found in the [terraform directory][terraform].

The pipeline currently deploys these components into the `cyber-sec-sandbox`
space of the `gds-security` org on GOV.UK PaaS.

To run the e2e tests you need a full test deployment of the stub, broker and
adapater, but if you want to run a test again an existing deployment you can do
this via concourse:

```
fly -t cd-cybersecurity-tools execute \
	-c ./ci/test.yml \
	-i src=.. \
	--var stub-url=https://test-csls-stub.cloudapps.digital
```

[pipeline]: https://cd.gds-reliability.engineering/?search=team%3A%20cybersecurity-tools
[terraform]: ./terraform
[broker]: ./cmd/broker
[stub]: ./cmd/stub
[adapter]: ./cmd/adapter
