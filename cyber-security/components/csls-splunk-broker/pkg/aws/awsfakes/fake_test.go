package awsfakes_test

import (
	"testing"

	"github.com/alphagov/tech-ops/cyber-security/components/csls-splunk-broker/pkg/aws"
	"github.com/alphagov/tech-ops/cyber-security/components/csls-splunk-broker/pkg/aws/awsfakes"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("FakeCloudfoundryLogPutter", func() {
	It("Satisfies the interface", func() {
		var _ aws.Client = &awsfakes.FakeClient{}
	})

})

func TestSyslogHttpAdapter(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "SyslogHttpAdapter Suite")
}
