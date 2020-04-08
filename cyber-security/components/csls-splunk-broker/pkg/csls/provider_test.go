package csls_test

import (
	"net/url"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"context"

	provideriface "github.com/alphagov/paas-service-broker-base/provider"
	"github.com/alphagov/tech-ops/cyber-security/components/csls-splunk-broker/pkg/csls"
	"github.com/pivotal-cf/brokerapi"
	"github.com/pivotal-cf/brokerapi/domain"
)

var _ = Describe("Provider", func() {
	var (
		splunkProvider *csls.SplunkProvider
		ctx            context.Context
	)

	const (
		drainURL  = "https://splunk.example.com/"
		secretKey = "correct-horse-battery-staple"
	)

	BeforeEach(func() {
		ctx = context.Background()
		var err error
		splunkProvider, err = csls.NewSplunkProvider(drainURL, secretKey)
		Expect(err).ToNot(HaveOccurred())
	})

	Context("when a service is created", func() {
		It("should not do anything interesting", func() {
			provisionData := provideriface.ProvisionData{
				InstanceID: "09E1993E-62E2-4040-ADF2-4D3EC741EFE6",
			}
			_, _, async, err := splunkProvider.Provision(ctx, provisionData)
			Expect(err).NotTo(HaveOccurred())
			Expect(async).To(BeFalse())
		})
	})

	Context("when a service is destroyed", func() {
		It("should not do anything interesting", func() {
			deprovisionData := provideriface.DeprovisionData{
				InstanceID: "09E1993E-62E2-4040-ADF2-4D3EC741EFE6",
			}
			_, async, err := splunkProvider.Deprovision(context.Background(), deprovisionData)
			Expect(err).NotTo(HaveOccurred())
			Expect(async).To(BeFalse())
		})
	})

	Context("when an application binds to the service", func() {
		It("should generate an authenticated syslog drain url for the bound app", func() {
			instanceID := "09E1993E-62E2-4040-ADF2-4D3EC741EFE6"
			bindingID := "D26EA3FB-AA78-451C-9ED0-233935ED388F"

			bindData := provideriface.BindData{
				InstanceID: instanceID,
				BindingID:  bindingID,
				Details: domain.BindDetails{
					AppGUID: "FC5EA2E4-6698-11EA-908D-33F3F969A30F",
				},
			}
			binding, err := splunkProvider.Bind(context.Background(), bindData)
			Expect(err).NotTo(HaveOccurred())
			Expect(binding.IsAsync).To(BeFalse())
			bindingURL, err := url.Parse(binding.SyslogDrainURL)
			Expect(err).ToNot(HaveOccurred())
			Expect(bindingURL.Hostname()).To(Equal("splunk.example.com"))
			Expect(bindingURL.Scheme).To(Equal("https"))
			Expect(bindingURL.Path).To(Equal("/"))
			bindingQuery := bindingURL.Query()
			bindingCode := bindingQuery.Get(csls.ParamMAC)
			Expect(bindingCode).ToNot(BeZero())
			ok, err := csls.VerifyMAC(bindData.Details.AppGUID, secretKey, bindingCode)
			Expect(err).ToNot(HaveOccurred())
			Expect(ok).To(BeTrue())
		})
	})

	Context("when an application unbinds from the service", func() {
		It("should not do anything interesting", func() {
			instanceID := "09E1993E-62E2-4040-ADF2-4D3EC741EFE6"
			bindingID := "D26EA3FB-AA78-451C-9ED0-233935ED388F"
			unbindData := provideriface.UnbindData{
				InstanceID: instanceID,
				BindingID:  bindingID,
			}
			unbinding, err := splunkProvider.Unbind(context.Background(), unbindData)
			Expect(err).NotTo(HaveOccurred())
			Expect(unbinding.IsAsync).To(BeFalse())
		})
	})

	Context("when user attempts to update service", func() {
		It("should report that this is impossible", func() {
			updateData := provideriface.UpdateData{
				InstanceID: "09E1993E-62E2-4040-ADF2-4D3EC741EFE6",
			}
			_, async, err := splunkProvider.Update(context.Background(), updateData)
			Expect(err).To(MatchError(csls.ErrUpdateNotSupported))
			Expect(async).To(BeFalse())
		})
	})

	Context("when LastOperation polling is attempted", func() {
		It("returns success unconditionally", func() {
			state, description, err := splunkProvider.LastOperation(context.Background(), provideriface.LastOperationData{})
			Expect(err).NotTo(HaveOccurred())
			Expect(description).To(Equal("Last operation polling not required. All operations are synchronous."))
			Expect(state).To(Equal(brokerapi.Succeeded))
		})
	})
})
