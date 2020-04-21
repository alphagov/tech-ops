package csls_test

import (
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"github.com/alphagov/tech-ops/cyber-security/components/csls-splunk-broker/pkg/csls"
)

var _ = Describe("HMAC", func() {

	const (
		appGUID             = "DF3FB5F4-311D-497C-A245-3F63642958CE"
		serviceInstanceGUID = "6B1107E7-57DC-4BC4-A766-5D73AD51EC26"
		secretKey           = "correct-horse-battery-staple"
	)

	It("should generate a message auth code for a given app GUID", func() {
		code, err := csls.GenerateMAC(appGUID, serviceInstanceGUID, secretKey)
		Expect(err).ToNot(HaveOccurred())
		Expect(len(code)).To(BeNumerically(">", 20))
	})

	It("should fail to generate if app GUID is blank", func() {
		_, err := csls.GenerateMAC("", serviceInstanceGUID, secretKey)
		Expect(err).To(Equal(csls.ErrInvalidMessageAuthArgs))
	})

	It("should fail to generate if service instance GUID is blank", func() {
		_, err := csls.GenerateMAC(appGUID, "", secretKey)
		Expect(err).To(Equal(csls.ErrInvalidMessageAuthArgs))
	})

	It("should fail to generate if secret key is blank", func() {
		_, err := csls.GenerateMAC(appGUID, serviceInstanceGUID, "")
		Expect(err).To(Equal(csls.ErrInvalidMessageAuthArgs))
	})

	It("should not generate same auth code for two different app GUIDs", func() {
		code1, _ := csls.GenerateMAC(appGUID, serviceInstanceGUID, secretKey)
		code2, _ := csls.GenerateMAC("2DDC7A37-2EF1-48C9-A532-2E04FCB07619", serviceInstanceGUID, secretKey)
		Expect(code1).ToNot(Equal(code2))
	})

	It("should not generate same auth code for two different service instance GUIDs", func() {
		code1, _ := csls.GenerateMAC(appGUID, serviceInstanceGUID, secretKey)
		code2, _ := csls.GenerateMAC(appGUID, "569581E5-50EF-4FA7-8F1C-529854B3079F", secretKey)
		Expect(code1).ToNot(Equal(code2))
	})

	It("should verify a valid hmac for given app and servie instance GUIDs", func() {
		codeToVerify, err := csls.GenerateMAC(appGUID, serviceInstanceGUID, secretKey)
		Expect(err).ToNot(HaveOccurred())
		ok, err := csls.VerifyMAC(appGUID, serviceInstanceGUID, secretKey, codeToVerify)
		Expect(err).ToNot(HaveOccurred())
		Expect(ok).To(BeTrue())
	})

	It("should fail to verify an for another app GUID", func() {
		codeToVerify, err := csls.GenerateMAC(appGUID, serviceInstanceGUID, secretKey)
		Expect(err).ToNot(HaveOccurred())
		sneakyAppGUID := "ACB5DE50-7A67-457C-B16F-D1F8990232CE"
		ok, err := csls.VerifyMAC(sneakyAppGUID, serviceInstanceGUID, secretKey, codeToVerify)
		Expect(err).ToNot(HaveOccurred())
		Expect(ok).To(BeFalse())
	})

	It("should fail to verify an for another service instance GUID", func() {
		codeToVerify, err := csls.GenerateMAC(appGUID, serviceInstanceGUID, secretKey)
		Expect(err).ToNot(HaveOccurred())
		sneakyInstanceGUID := "B0D28FBE-4CDD-4DCF-9603-9821C44ABC8B"
		ok, err := csls.VerifyMAC(appGUID, sneakyInstanceGUID, secretKey, codeToVerify)
		Expect(err).ToNot(HaveOccurred())
		Expect(ok).To(BeFalse())
	})

	It("should fail to verify if appGUID is blank", func() {
		codeToVerify, err := csls.GenerateMAC(appGUID, serviceInstanceGUID, secretKey)
		Expect(err).ToNot(HaveOccurred())
		ok, err := csls.VerifyMAC("", serviceInstanceGUID, secretKey, codeToVerify)
		Expect(err).To(Equal(csls.ErrInvalidMessageAuthArgs))
		Expect(ok).To(BeFalse())
	})

	It("should fail to verify if service instance GUID is blank", func() {
		codeToVerify, err := csls.GenerateMAC(appGUID, serviceInstanceGUID, secretKey)
		Expect(err).ToNot(HaveOccurred())
		ok, err := csls.VerifyMAC(appGUID, "", secretKey, codeToVerify)
		Expect(err).To(Equal(csls.ErrInvalidMessageAuthArgs))
		Expect(ok).To(BeFalse())
	})

	It("should fail to verify if secret key is blank", func() {
		codeToVerify, err := csls.GenerateMAC(appGUID, serviceInstanceGUID, secretKey)
		Expect(err).ToNot(HaveOccurred())
		ok, err := csls.VerifyMAC(appGUID, serviceInstanceGUID, "", codeToVerify)
		Expect(err).To(Equal(csls.ErrInvalidMessageAuthArgs))
		Expect(ok).To(BeFalse())
	})

	It("should fail to verify if code is blank", func() {
		ok, err := csls.VerifyMAC(appGUID, serviceInstanceGUID, secretKey, "")
		Expect(err).To(Equal(csls.ErrInvalidMessageAuthArgs))
		Expect(ok).To(BeFalse())
	})
})
