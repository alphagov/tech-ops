package csls_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"github.com/alphagov/tech-ops/cyber-security/components/csls-splunk-broker/pkg/csls"
)

var _ = Describe("HMAC", func() {

	const (
		appGUID   = "DF3FB5F4-311D-497C-A245-3F63642958CE"
		secretKey = "correct-horse-battery-staple"
	)

	It("should generate a message auth code for a given app GUID", func() {
		code, err := csls.GenerateMAC(appGUID, secretKey)
		Expect(err).ToNot(HaveOccurred())
		Expect(len(code)).To(BeNumerically(">", 20))
	})

	It("should not generate same auth code for two different app GUIDs", func() {
		code1, _ := csls.GenerateMAC(appGUID, secretKey)
		code2, _ := csls.GenerateMAC("2DDC7A37-2EF1-48C9-A532-2E04FCB07619", secretKey)
		Expect(code1).ToNot(Equal(code2))
	})

	It("should verify a valid hmac for a given app GUID", func() {
		codeToVerify, err := csls.GenerateMAC(appGUID, secretKey)
		Expect(err).ToNot(HaveOccurred())
		ok, err := csls.VerifyMAC(appGUID, secretKey, codeToVerify)
		Expect(err).ToNot(HaveOccurred())
		Expect(ok).To(BeTrue())
	})

	It("should fail to verify an for another app GUID", func() {
		codeToVerify, err := csls.GenerateMAC(appGUID, secretKey)
		Expect(err).ToNot(HaveOccurred())
		sneakyAppGUID := "ACB5DE50-7A67-457C-B16F-D1F8990232CE"
		ok, err := csls.VerifyMAC(sneakyAppGUID, secretKey, codeToVerify)
		Expect(err).ToNot(HaveOccurred())
		Expect(ok).To(BeFalse())
	})
})
