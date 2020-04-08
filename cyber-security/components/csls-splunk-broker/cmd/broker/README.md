# csls cloudfoundry broker

## Overview

Implements cloudfoundry (Open Service Broker) API to provision syslog drain
URLs for each application binding.

## Usage

```
CSLS_ADAPTER_URL=<url-to-adapter-endpoint> \
CSLS_HMAC_SECRET=<secret-shared-with-adapter> \
BROKER_USERNAME=<secret-shared-with-paas> \
BROKER_PASSWORD=<secret-shared-with-paas> \
	go run ./cmd/broker
```
