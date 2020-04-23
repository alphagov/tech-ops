# ADR006: Mapping log events to splunk indexes

## Context

We need to provide the [CSLS Processor][processor] with information suitable
for it to map log events coming from the Adapter to manually configured Splunk
indexes for the tenant.

The Processor [maps log events to indexes][mapping] based on the combination of the `Owner`
and `LogGroupName` fields in the CSLS/CloudWatch log format.

The Adapter currently sets the `Owner` field to the static string "GOV.UK_PaaS"
and the `LogGroupName` to the static string "rfc5424_syslog".

All logs shipped through the Adapter currently end up in a single index in splunk.

A single index in splunk is NOT suitable for teams with security and compliance
requirements, who need fine grained control over access control.

## Decision

We will set the `LogGroupName` on logs emitted from the Adapter to the
Cloudfoundry service instance GUID of the splunk service provisioned by the
tenant.

## Consequences

By using the service instance GUID (a value available as part of the binding
request data) we avoid needing to communicate with the GOV.UK PaaS API to
retrive human friendly names for the relevent org/space which would have
significantly increased the complexity of the applications and required
management of broadly scoped credentials.

By using the service instance GUID instead of a more human friendly name (such
as the org, space or service name) we avoid potential issues due to the
mutability of these values. A tenant could rename these things and is unlikely
to think this would affect log shipping.

By using the service instance GUID we avoid confusion that could be caused by
the ability to share [service instances between spaces][sharing].

By using the service instance GUID we enable tenants to ship logs to different
indexes from within the same space by creating multiple service instances and
binding apps to each one seperately.

By using a GUID it may not always be obvious to human eyes the source of the
log event, making the mapping part of the onboarding process more important.

By using a service instance GUID tenants and those operating the csls service
will need to be aware that destroying/recreating the service instance will
require updating the mapping in the [processor][processor]

[processor]: https://github.com/alphagov/centralised-security-logging-service/tree/master/kinesis_processor
[sharing]: https://docs.cloudfoundry.org/devguide/services/sharing-instances.html
[mapping]: https://github.com/alphagov/centralised-security-logging-service/blob/master/kinesis_processor/accounts_loggroup_index.toml
