# ADR004: Deploying Broker using AWS Lambda

## Context

We need to deploy the Broker somewhere.

The Broker implements the service broker API to generate per-application syslog
drain URLs (Adapter URLs).

The Adapter is written in Go.

The Broker is written in Go.

The Adapter runs as a lambda in AWS alongside the CSLS infrastructure.

We have a pipeline to continuously build, test, deploy the Adapter to lambda.

## Decision

We will deploy the Broker as an AWS Lambda

## Consequences

By deploying the Broker as a Lambda, we can take advantage of the existing
terraform and pipeline steps already in place for the Adapter.

