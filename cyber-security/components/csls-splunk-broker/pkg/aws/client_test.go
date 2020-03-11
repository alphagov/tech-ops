package aws_test

import (
	"github.com/alphagov/tech-ops/cyber-security/components/csls-splunk-broker/pkg/aws"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Client", func() {

	var (
		client aws.Client
	)

	BeforeEach(func() {
		var err error
		client, err = aws.NewClient(nil)
		Expect(err).ToNot(HaveOccurred())
	})

	It("can assume a role", func() {
		_, err := client.AssumeRole("my-role")
		Expect(err).ToNot(HaveOccurred())
	})

	It("can (attempt) to put record to kinesis", func() {
		_, err := client.PutRecord(nil)
		Expect(err).ToNot(Succeed())
	})

})
