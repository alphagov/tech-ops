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
	appPath, err = Build("github.com/alphagov/tech-ops/cyber-security/components/csls-splunk-broker/cmd/adapter")
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
			"CSLS_ROLE_ARN=test-arn",
			"CSLS_HMAC_SECRET=test-secret",
			"CSLS_STREAM_NAME=test-stream-name",
		}
	})

	It("should start an http server when if PORT is given", func() {
		cmd.Env = append(cmd.Env, "PORT=8080")
		session, err := Start(cmd, GinkgoWriter, GinkgoWriter)
		Expect(err).NotTo(HaveOccurred())
		defer session.Kill()
		Eventually(session.Out).Should(Say("starting http server"))
		Eventually(session).ShouldNot(Exit())
	})

	It("should configure a lambda handler if PORT not given", func() {
		session, err := Start(cmd, GinkgoWriter, GinkgoWriter)
		Expect(err).NotTo(HaveOccurred())
		defer session.Kill()
		Eventually(session.Out).Should(Say("starting lambda server"))
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
		Entry("username", "CSLS_STREAM_NAME"),
		Entry("password", "CSLS_ROLE_ARN"),
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
