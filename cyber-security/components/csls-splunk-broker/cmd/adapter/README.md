# csls syslog over http adapter

## Overview

Starts an HTTP (or AWS API Gateway) service that accepts cloudfoundry format
syslog-over-http requests and forwards them to a kinesis stream in CSLS log format.

## Usage

```
CSLS_ROLE_ARN=<arn-with-access-to-kinesis> \
CSLS_HMAC_SECRET=<secret-shared-with-broker> \
CSLS_STREAM_NAME=<kinesis-stream-send-to> \
	go run ./cmd/adapter
```
