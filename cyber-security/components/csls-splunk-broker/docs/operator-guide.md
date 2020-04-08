# Operator guidance for deploying the CSLS splunk broker

## Overview

csls-splunk-broker allows GOV.UK PaaS tenants to ship/store their application logs
in Splunk managed by the GDS Cyber Security Team.

There are two main components of the system; The Broker (that implements the Open
Service Broker API to provision syslog drains) and a the Adapter (that
translates syslog formatted log lines into csls format log events).

For more details about it works, architecture and implementation visit the
[architectual design and decisions][architecture] documentation.

## Deployment

--------- pic of deployment layout

The components ([Broker][broker] and [Adapter][adapter] are deployed to AWS
Lambda continuously deployed from this repository by the  pipeline in the
[cybersecurity-tools concourse][pipeline] to the `security-cls` AWS account.

The [Stub][stub] component (an application that generates log load for the
end-to-end test) is deployed to the `cyber-sec-sandbox` space in the
`gds-security` org on GOV.UK PaaS (ireland).

The deployment configuration of the entire system is managed by Terraform and
can be found in the [terraform directory][terraform]


## Broker registration

Before the `splunk` service can be enabled for a GOV.UK PaaS org, the broker
must be registered in the target GOV.UK PaaS region.

The broker is already registered for use in GOV.UK PaaS Ireland region.

The [Broker][broker] was [manually registered][register-broker] by a GOV.UK PaaS
administrator by running:

```
cf create-service-broker splunk USERNAME PASSWORD URL
```

Where:

* `USERNAME` and `PASSWORD` are secrets that are stored in [the pipeline][pipeline]
* `URL` is the production broker URL that can be obtained by observing the output from the deploy job in [the pipeline][pipeline]

## Enabling service access

Before the `splunk` plan will be visible in the `cf marketplace`, the plan must
be enabled for the target GOV.UK PaaS Org.

The `splunk` plan must be manually enabled by a GOV.UK PaaS administrator by running:

```
cf enable-service-access splunk -b splunk -o ORG_NAME
```

Where `ORG_NAME` is the organisation that requires use of the `splunk` service.

For more information on onboarding a new GOV.UK PaaS tenant to use the service see
the [User Guidance][user-guide]

## Pipeline

The [deployment pipeline][pipeline] continuously builds, tests and deploys the
components in this repository.

The pipeline process is generally:

* build and test the [Broker][broker], [Adaptor][adapter] and [Stub][stub] component binaries
* provision a staging instance of the system in the `security-test` AWS account
* runs an e2e test against it
* deploys the production instance of the system in the `security-cls` AWS account

You shouldn't need to, but you can manually set the deployment pipeline using fly:

```
fly -t cd-cybersecurity-tools set-pipeline \
	-p csls-splunk-broker \
	-c ./ci/pipeline.yml
```

## Development

The components are written in [Go][go], make use of [Go Modules][go-mod] and
their entrypoints can be found in the [cmd dir][cmd]:

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

[pipeline]: https://cd.gds-reliability.engineering/teams/cybersecurity-tools/pipelines/csls-splunk-broker
[terraform]: ../terraform
[broker]: ../cmd/broker/README.md
[stub]: ../cmd/stub/README.md
[adapter]: ../cmd/adapter/README.md
[architecture]: ./architecture-guide.md
[register-broker]: https://docs.cloudfoundry.org/services/managing-service-brokers.html#register-broker
[user-guide]: ./user-guide.md
[cmd]: ../cmd/
[go]: https://golang.org/
[go-mod]: https://blog.golang.org/using-go-modules
