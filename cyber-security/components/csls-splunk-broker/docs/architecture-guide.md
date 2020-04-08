# Architectual design and decisions of csls-splunk-broker

## Overview

------------ picture of how it works

## Design Decisions

* [ADR001: Build a syslog-http to csls adapter][ADR001]
* [ADR002: Deploying the Adapter as Lambda][ADR002]
* [ADR003: Implementing a Service Broker][ADR003]
* [ADR004: Deploying the Broker as Lambda][ADR004]
* [ADR005: Authenticating log events][ADR005]

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

[ADR001]: ./adr/ADR001-syslog-http-to-csls-adapter.md
[ADR002]: ./adr/ADR002-deploy-adatper-as-lambda.md
[ADR003]: ./adr/ADR003-service-broker.md
[ADR004]: ./adr/ADR004-deploy-broker-as-lambda.md
[ADR005]: ./adr/ADR005-authenticating-log-events.md
