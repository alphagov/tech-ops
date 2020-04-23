# User guidance for shipping logs to Splunk

## Overview

This guidance is for GOV.UK PaaS tenants who want to ship their application
logs to the GDS Cyber Security managed Splunk service.

## Setting up the Splunk service

### Request access to the Splunk service

The Splunk service is not available to all GOV.UK PaaS tenants by default, and
access to view/query logs via the Splunk UI is granted to Google accounts on a
per-user basis. So before you can make use of the service there are a couple of
manual steps that need to be processed:

1. Communicate your needs to the GDS Cyber Security team. By visting the
   `#cyber-security-help` channel in slack and requesting that you would like
   to store your GOV.UK PaaS application logs in Splunk and will require
   access for your team to view and query your logs.

2. Request access to the Splunk service from the GOV.UK PaaS team.

   You can contact the GOV.UK PaaS team either via `#paas` on slack or via the offical
   [support system](https://www.cloud.service.gov.uk/support)

   A GOV.UK PaaS administrator will need to perform `cf enable-service-access splunk -b
   splunk -o $YOUR_ORG` on your behalf which will make the `splunk` service
   visible in the `cf marketplace` for your GOV.UK PaaS organisation.

### Set up a Splunk service

1. List the plans available for Splunk by running:

   ```
   cf marketplace -s splunk
   ```

   Here is an example of the output you will see:

   ```
   service plan   description                       free or paid
   unlimited      unmetered usage for GDS tenants   free
   ```

2. Create a service instance:

   ```
   cf create-service splunk unlimited SERVICE_NAME
   ```

   Where `SERVICE_NAME` is a unique descriptive name for this service
   instance. For example:

   ```
   cf create-service splunk unlimited my-splunk-service
   ```

   To confirm you have successfully set up your splunk service, run:

   ```
   cf service SERVICE_NAME
   ```

   for example:

   ```
   cf service my-splunk-service
   ```

   When cf service SERVICE_NAME returns a create succeeded status, you have set
   up the service instance. An example output could be:

   ```
   name:            my-splunk-service
   service:         splunk
   tags:
   plan:            unlimited
   description:     Log storage, analytics and protective monitoring by GDS Cyber Security
   documentation:
   dashboard:

   There are no bound apps for this service.
   ```

### Bind a Splunk service to your apps using an app manifest

You must bind your app to the Splunk service to access the Splunk database from your app.

1. Use the [app’s manifest][manifest] to bind the app to the service instance.
   It will bind automatically when you next deploy your app.
2. Deploy your app in line with your normal deployment process.

Refer to the [Cloud Foundry documentation on deploying with app
manifests][manifest-deploy] for more information.

### Bind a Splunk service to your app using cf bind-service

If your app does not have a manifest file, you can manually bind your service instance to your app.

1. Run the following:

   ```
   cf bind-service APP_NAME SERVICE_NAME
   ```

   where:

   * `APP_NAME` is the exact name of a deployed instance of your app
   * `SERVICE_NAME` is the name of the service instance you created

   For example:

   ```
   cf bind-service my-app my-splynk-service
   ```

2. Deploy your app in line with your normal deployment process.

## Using the Splunk service

Once an application has been bound to the service, it will automatically begin
sending any log traffic written by your application to [`stdout`][app-logging]
or [`stderr`][app-logging] to Splunk.

Assuming you have been given the requisite access, you will be able to view
and query your logs in the [Splunk UI][splunk-ui].

### Routing logs to splunk indexes

Splunk stores logs in seperate buckets that it calls "indexes". Initially all
your logs will end up in the `csls_unrecognised_data` index, but you will
likely want to request that your logs are routed to your own private index.

Log events shipped to splunk have their `sourcetype` metadata set to the
service instance GUID of the service you have bound your application to. (see
the metadata section below).

Log events are routed to splunk indexes based on the the GUID of the service
instance that you created.

To have your logs routed to your own index you need to:

1. Discover the GUID of your service instance `cf service my-splunk-service --guid`
2. Make a request to Cyber Security team that you want your logs shipped to a
   seperate index and provide them with the service-instance GUID obtained
   above.

### Log event metadata

Your logs will have the following metadata fields added to them to aid with
indexing and querying:

#### Source field

The `source` field contains details about which stream from which process from
which app from which space from which org the log originated from. For example:

A `source` field for `my-app` in `my-space` which is part of `my-org` might
look like `gov.uk_paas:/my-org/my-space/my-app/my-process/0`

Splunk supports wildcard queries so it is often useful to use this field to
query for logs from multiple sources within the same org or space. For example:

```
source="gov.uk_paas:/ORG_NAME/SPACE_NAME/*"
```

Where `ORG_NAME` and `SPACE_NAME` are replaced by your unique values.

#### Timestamp field

The `timestamp` field will be set to the time that the log line was received by
GOV.UK PaaS.

#### Sourcetype field

The `sourcetype` field contains the service instance GUID of the GOV.UK PaaS
service instance that the application was bound to. This value is used by the
[CSLS processor][processor] to route log events to the correct index.

You can use this field to filter your logs to the specific service instance you
have bound your application logs to. For example you may have serpate `splunk`
services for your `production` and `staging` logs, and each will have a unique
GUID that can be used to find all logs for that environment.

You can view the guid for your service instance using the following command:

```
cf service SERVICE_NAME --guid
```

You may then use that value in a splunk query, for example:

```
sourcetype="608BA116-EF5C-4AF6-9AF1-7400FE1C3DFD"
```

## Removing the Splunk service

### Unbind a Splunk service from your app

You must unbind the Splunk service before you can delete it:

```
cf unbind-service APP_NAME SERVICE_NAME
```

where:

`APP_NAME` is your app’s deployed instance name as specified in your app’s
manifest.yml or push command `SERVICE_NAME` is a unique descriptive name for
this service instance For example:

```
cf unbind-service my-app my-splunk-service
```

If you unbind your service from your app but do not delete it, the service
will persist even after you have deleted your app. You can re-bind or
re-connect to it in future.

### Delete a Splunk service

Once you have unbound the Splunk service from your app, you can delete the service:

```
cf delete-service SERVICE_NAME
```

where `SERVICE_NAME` is a unique descriptive name for this service instance. For example:

```
cf delete-service my-splunk-service
```

## Maintaining the Splunk service

### Data retention

Logs are stored in splunk for 1 year.


[manifest]: https://docs.cloud.service.gov.uk/deploying_apps.html#deploying-public-apps
[manifest-deploy]: https://docs.cloudfoundry.org/devguide/deploy-apps/manifest.html#services-block
[splunk-ui]: https://gds.splunkcloud.com/
[app-logging]: https://docs.cloud.service.gov.uk/monitoring_apps.html#logs
[processor]: https://github.com/alphagov/centralised-security-logging-service/tree/master/kinesis_processor
