# ADR003: Implementing a Service Broker

## Context

We need to prevent TenantA from being able to write TenantB's log events.

The Adapter accepts log events over HTTP.

There is a single URL endpoint for the adapter.

To configure a GOV.UK PaaS application to send logs to the Adapter's URL you must
bind your application to a [cloudfoundry service][openservicebroker] that provides a syslog-drain.

You can create a user-provided-service in GOV.UK PaaS that enables tenants to
manually configure their own syslog-drain endpoint.

The URL for the syslog-drain can be read by inspecting an application's environment.

Having the URL is all you currently need to send any logs masquerading as any application.

## Decision

We will implement a [cloudfoundry broker][openservicebroker] that generates a
unique per-application URL when the application [binds][bind] to the service.

## Consequences

By a URL that only allows sending logs for a given application GUID, we
mitigate the risk that TenantA can use their own adapter URL to send log
traffic that affects TenantB.

By having a broker generate the URLs we avoid the need to manually manage
authentication details per-application in the adapter.

By implementing a broker will we have more to maintain and deploy, however
since we have no "provision" or "deprovision" steps to implement, this code is
mostly boilerplate.


[openservicebroker]: https://www.openservicebrokerapi.org/
[bind]: https://github.com/openservicebrokerapi/servicebroker/blob/master/spec.md#binding
