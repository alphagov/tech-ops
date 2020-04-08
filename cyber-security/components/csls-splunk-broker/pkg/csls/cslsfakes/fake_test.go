package cslsfakes_test

import (
	"testing"

	"github.com/alphagov/tech-ops/cyber-security/components/csls-splunk-broker/pkg/csls"
	"github.com/alphagov/tech-ops/cyber-security/components/csls-splunk-broker/pkg/csls/cslsfakes"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("FakeCloudfoundryLogPutter", func() {
	It("Satisfies the interface", func() {
		var _ csls.CloudfoundryLogPutter = &cslsfakes.FakeCloudfoundryLogPutter{}
	})

})

func TestSyslogHttpAdapter(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "SyslogHttpAdapter Suite")
}
