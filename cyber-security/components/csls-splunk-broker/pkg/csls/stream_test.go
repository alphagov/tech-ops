package csls_test

import (
	"encoding/json"
	"time"

	"github.com/alphagov/tech-ops/cyber-security/components/csls-splunk-broker/pkg/aws/awsfakes"
	"github.com/alphagov/tech-ops/cyber-security/components/csls-splunk-broker/pkg/cloudfoundry"
	"github.com/alphagov/tech-ops/cyber-security/components/csls-splunk-broker/pkg/csls"
	"github.com/aws/aws-sdk-go/aws"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Stream", func() {

	var (
		stream *csls.Stream
		client *awsfakes.FakeClient
		input  cloudfoundry.Log
		output csls.Log
	)

	BeforeEach(func() {
		client = &awsfakes.FakeClient{}
		stream = &csls.Stream{
			Name: "test-stream-name",
			AWS:  client,
		}
		input = cloudfoundry.Log{
			Timestamp: time.Now(),
			Hostname:  "org.space.app",
			AppID:     "5294D7C2-0413-4282-A016-BD8E13AE6264",
			ProcessID: "[APP/1]",
			Message:   "hello world\n",
		}
		Expect(stream.PutCloudfoundryLog(input)).To(Succeed())
		Expect(client.PutRecordCallCount()).To(Equal(1))
		Expect(json.Unmarshal(client.PutRecordArgsForCall(0).Data, &output)).To(Succeed())
	})

	It("should set the correct stream name", func() {
		record := client.PutRecordArgsForCall(0)
		Expect(record.StreamName).To(Equal(aws.String("test-stream-name")))
	})

	It("should set partition key to the hostname", func() {
		record := client.PutRecordArgsForCall(0)
		Expect(record.PartitionKey).To(Equal(aws.String("org.space.app")))
	})

	It("should set the owner on output log", func() {
		Expect(output.Owner).To(Equal("GOV.UK_PaaS"))
	})

	It("should set the log group on output log", func() {
		Expect(output.LogGroup).To(Equal("rfc5424_syslog"))
	})

	It("should set the log stream on output log", func() {
		Expect(output.LogStream).To(Equal("org.space.app"))
	})

	It("should set the correct message type on output log", func() {
		Expect(output.MessageType).To(Equal("DATA_MESSAGE"))
	})

	It("should set the log event", func() {
		Expect(output.LogEvents).To(ConsistOf(csls.LogEvent{
			ID:        "0",
			Timestamp: input.Timestamp.Unix(),
			Message:   "hello world\n",
		}))
	})

})
