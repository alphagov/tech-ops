package cloudfoundry_test

import (
	"time"

	"github.com/alphagov/tech-ops/cyber-security/components/csls-splunk-broker/pkg/cloudfoundry"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Log", func() {

	var (
		log cloudfoundry.Log
	)

	Context("when unmarshalling valid syslog bytes", func() {

		BeforeEach(func() {
			log = cloudfoundry.Log{}
			b := []byte("<14>1 2001-01-01T01:01:01.0+00:00 myorg.myspace.myapp test-app-id [MY-TASK/2] - [tags@47450 source_type=\"MY TASK\"] just a test\n")
			Expect(cloudfoundry.UnmarshalRFC5424(b, &log)).To(Succeed())
		})

		It("extracts hostname", func() {
			Expect(log.Hostname).To(Equal("myorg.myspace.myapp"))
		})

		It("extracts app guid", func() {
			Expect(log.AppID).To(Equal("test-app-id"))
		})

		It("extracts log message", func() {
			Expect(log.Message).To(Equal("just a test\n"))
		})

		It("extracts timestamp", func() {
			ts := time.Date(2001, time.January, 1, 1, 1, 1, 0, time.UTC)
			Expect(log.Timestamp).To(Equal(ts))
		})

	})

	Context("when unmarshalling invalid syslog bytes", func() {

		It("fails to parse", func() {
			b := []byte("<14>1 2001-01-01T01:01:01.0+00:00 test-app-id [MY-TASK/2] - [tags@47450 source_type=\"MY TASK\"] just a test\n")
			Expect(cloudfoundry.UnmarshalRFC5424(b, &log)).To(MatchError(ContainSubstring("failed-to-parse-rfc5424")))
		})

	})

})
