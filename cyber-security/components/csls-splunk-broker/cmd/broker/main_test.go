package main_test

import (
	"fmt"
	"os/exec"
	"strings"
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/ginkgo/extensions/table"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gbytes"
	. "github.com/onsi/gomega/gexec"
)

var appPath string

var _ = BeforeSuite(func() {
	var err error
	appPath, err = Build("github.com/alphagov/tech-ops/cyber-security/components/csls-splunk-broker/cmd/broker")
	Expect(err).NotTo(HaveOccurred())
})

var _ = AfterSuite(func() {
	CleanupBuildArtifacts()
})

var _ = Describe("adapter", func() {

	var (
		cmd *exec.Cmd
	)

	BeforeEach(func() {
		cmd = exec.Command(appPath)
		cmd.Env = []string{
			"CSLS_ADAPTER_URL=https://adapter.example.com/",
			"CSLS_HMAC_SECRET=test-secret-battery-stable",
			"BROKER_USERNAME=test-username",
			"BROKER_PASSWORD=test-password",
		}
	})

	It("should configure a lambda handler and start", func() {
		session, err := Start(cmd, GinkgoWriter, GinkgoWriter)
		Expect(err).NotTo(HaveOccurred())
		defer session.Kill()
		Eventually(session.Out).Should(Say("splunk service broker started"))
		Eventually(session).ShouldNot(Exit())
	})

	DescribeTable("should fail to start if missing environment variable", func(missingVar string) {
		cmd.Env = WithoutVariable(cmd.Env, missingVar)
		session, err := Start(cmd, GinkgoWriter, GinkgoWriter)
		Expect(err).NotTo(HaveOccurred())
		defer session.Kill()
		Eventually(session.Err).Should(Say(fmt.Sprintf("%s is required", missingVar)))
		Eventually(session).Should(Exit(2))
	},
		Entry("username", "BROKER_USERNAME"),
		Entry("password", "BROKER_PASSWORD"),
		Entry("adapater", "CSLS_ADAPTER_URL"),
		Entry("secret", "CSLS_HMAC_SECRET"),
	)

})

func TestSyslogHttpAdapter(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "SyslogHttpAdapter Suite")
}

// WithoutVariable ignores a matching item from the list
func WithoutVariable(env []string, sub string) []string {
	list := []string{}
	for _, envvar := range env {
		if strings.Contains(envvar, sub) {
			continue
		}
		list = append(list, envvar)
	}
	return list
}
