package csls

import (
	"encoding/json"
	"fmt"

	sdk "github.com/alphagov/tech-ops/cyber-security/components/csls-splunk-broker/pkg/aws"
	"github.com/alphagov/tech-ops/cyber-security/components/csls-splunk-broker/pkg/cloudfoundry"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/kinesis"
)

const (
	SyslogLogGroup = "rfc5424_syslog"
	SyslogOwner    = "GOV.UK_PaaS"
	SyslogDataType = "DATA_MESSAGE"
)

// LogEvent represents a log message. It mirrors the format of the AWS
// Cloudwatch log event envelope
type LogEvent struct {
	ID        string `json:"id"`
	Timestamp int64  `json:"timestamp"`
	Message   string `json:"message"`
}

// Log represents a collection of Log messages from the same source. It is a
// duplicate of the AWS Cloudwatch Log envelope.
type Log struct {
	Owner               string     `json:"owner"`
	LogGroup            string     `json:"logGroup"`
	LogStream           string     `json:"logStream"`
	SubscriptionFilters []string   `json:"subscriptionFilters"`
	MessageType         string     `json:"messageType"`
	LogEvents           []LogEvent `json:"logEvents"`
}

//go:generate go run github.com/maxbrunsfeld/counterfeiter/v6 . CloudfoundryLogPutter

// CloudfoundryLogPutter forwards cloudfoundry format Logs to stream
type CloudfoundryLogPutter interface {
	PutCloudfoundryLog(log cloudfoundry.Log, logGroupName string) error
}

// Stream represents the input to the csls logging pipeline
type Stream struct {
	// Name is the name of the kinesis stream to write to
	Name string
	// Client is the AWS SDK capable of PutRecord
	AWS sdk.Client
}

// PutCloudfoundryLog transforms cloudfoundry format logs into csls format
// (cloudwatch format) logs and writes them to the csls kinesis stream with a
// given log group name
func (w *Stream) PutCloudfoundryLog(log cloudfoundry.Log, groupName string) error {
	data := Log{
		Owner:       SyslogOwner,
		LogGroup:    groupName,
		LogStream:   log.Hostname,
		MessageType: SyslogDataType,
		LogEvents: []LogEvent{
			{
				ID:        "0",
				Timestamp: log.Timestamp.Unix(), // TODO: should this be UnixNano?
				Message:   log.Message,
			},
		},
	}
	b, err := json.Marshal(data)
	if err != nil {
		return fmt.Errorf("failed-to-marshal-batch: %s", err)
	}
	_, err = w.AWS.PutRecord(&kinesis.PutRecordInput{
		StreamName:   aws.String(w.Name),
		Data:         b,
		PartitionKey: aws.String(log.Hostname),
	})
	if err != nil {
		return err
	}
	return nil
}
