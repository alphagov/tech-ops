# ADR001: syslog-http to csls-splunk adapter

## Context

We want to provide a reliable method of shipping logs from applications (on
GOV.UK Paas) to Splunk so they can take advantage of the log storage, analytics
and protective monitoring provided by the GDS Cyber Security team.

GDS Cyber Security maintain an [AWS Kinesis][kinesis] based log shipping stream
that accepts log events in the [AWS CloudWatch Logs][cloudwatch] format and
queues them for delivery to Splunk.

GOV.UK PaaS supports forwarding log events from an application's stdout and
stderr streams in [syslog format][syslog] via [syslog drains][drains].

Components such as [Fluentd][fluentd] are available that process and forwarding
logs from various sources to various targets, but their configuration can
unweildly and hard to test.

GOV.UK PaaS Tenants can run [sidecar][sidecar] containers to handle custom log
shipping or instument their applications with [logging libraries that support
multiple transports][winston], but this brings extra complexity and doesn't
make use of supported logging infrastructure already provided by GOV.UK PaaS.

## Decision

We will build an "adapter" application to deploy alongside the CSLS logging
pipeline that accepts requests in the "syslog over http" format exported by the
GOV.UK PaaS syslog drain system, translates them into the CloudWatch Logs
format and forwards them on to the CSLS Kinesis stream.

## Consequences

By making use of the GOV.UK PaaS syslog drain features, we are well placed to
provide as close to a PaaS-native user interaction as possible, and can
beneifit from the log shipping retries built in to the syslog shipping system.

By writing our own small, focused application rather than using
something "off the shelf" such as Fluentd, we believe we can acheive greater
reliablility through more testable code/configuration.

By using the syslog-http (rather than standard syslog-tcp) protocol we believe
we will keep our options for deployment open as most services handle HTTP
traffic, but TCP/UDP traffic is rarer. (For example, if we want to deploy the
adapter to PaaS, HTTP would be the only option).

By deploying a shared adapter component like this (rather than putting the
burden on each tenant) there will be additional ongoing maintaince to support
it.

[kinesis]: https://aws.amazon.com/kinesis/
[cloudwatch]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/WhatIsCloudWatchLogs.html
[syslog]: https://tools.ietf.org/html/rfc5424
[drains]: https://docs.cloudfoundry.org/devguide/services/log-management.html
[sidecar]: https://docs.microsoft.com/en-us/azure/architecture/patterns/sidecar
[winston]: https://github.com/winstonjs/winston#transports
