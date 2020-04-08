# ADR002: Deploying the Adapter using AWS Lambda

## Context

We need to deploy the Adapter somewhere.

The adapter accepts log events as [syslog-http][syslog] requests and forwards
them on to the CSLS managed Kinesis stream for processing into Splunk.

The Adapter could be hosted via any mechanism that supports HTTP (including
GOV.UK PaaS itself).

The Adapter requires AWS IAM credentials to write to the CSLS Kinesis stream.

GOV.UK PaaS logging system sends one HTTP request per log line.

Some tenants generate very large volumes of log events (upwards of 100/s).

## Decision

We will deploy the Adapter as an [AWS Lambda][lambda] into the same account as
the other CSLS infrastructure.

## Consequences

By running the Adapter in AWS we can take advantage of IAM profiles and avoid
the need to manually manage long lived credentials for access to the stream.

By using AWS Lambda we hope to reduce the need for monitoring and tuning scale
due to large volumes of traffic.

By not using GOV.UK PaaS we avoid putting a large unnecasary volume of
non-application traffic through the "front door" of PaaS.


[lambda]: https://aws.amazon.com/lambda/
[syslog]: https://tools.ietf.org/html/rfc5424
