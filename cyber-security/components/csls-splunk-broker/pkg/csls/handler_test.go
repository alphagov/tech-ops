package csls_test

import (
	"crypto/tls"
	"net/http"
	"net/http/httptest"
	"time"

	"code.cloudfoundry.org/go-loggregator/rpc/loggregator_v2"
	metricsHelpers "code.cloudfoundry.org/go-metric-registry/testhelpers"
	"code.cloudfoundry.org/loggregator-agent-release/src/pkg/egress"
	"code.cloudfoundry.org/loggregator-agent-release/src/pkg/egress/syslog"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"

	"github.com/alphagov/tech-ops/cyber-security/components/csls-splunk-broker/pkg/cloudfoundry"
	"github.com/alphagov/tech-ops/cyber-security/components/csls-splunk-broker/pkg/csls"
	"github.com/alphagov/tech-ops/cyber-security/components/csls-splunk-broker/pkg/csls/cslsfakes"
)

var _ = Describe("Handler", func() {
	var (
		appGUID   = "DF3FB5F4-311D-497C-A245-3F63642958CE"
		secretKey = "correct-horse-battery-staple"
		stream    *cslsfakes.FakeCloudfoundryLogPutter
		handler   http.Handler
		ts        *httptest.Server
		logs      egress.WriteCloser
	)

	BeforeEach(func() {
		stream = &cslsfakes.FakeCloudfoundryLogPutter{}
		handler = &csls.Handler{
			Stream: stream,
			Secret: secretKey,
		}
		ts = httptest.NewServer(handler)
		logs = newSyslogHTTPSWriter(
			ts.URL,
			appGUID,
			secretKey,
		)
	})

	AfterEach(func() {
		ts.Close()
	})

	It("reads RFC5424 encoded log messages from http and forwards them to stream", func() {
		log1 := newAppLog(appGUID, "APP_OUT_LOG_MESSAGE\n")
		log2 := newAppLog(appGUID, "APP_ERR_LOG_MESSAGE\n")
		Expect(logs.Write(log1)).To(Succeed())
		Expect(logs.Write(log2)).To(Succeed())
		Expect(stream.PutCloudfoundryLogCallCount()).To(Equal(2))
		Expect(stream.PutCloudfoundryLogArgsForCall(0)).To(BeEquivalentTo(cloudfoundry.Log{
			Timestamp: time.Unix(0, log1.Timestamp).UTC(),
			Hostname:  "org.space.app",
			AppID:     appGUID,
			ProcessID: "[APP/1]",
			Message:   "APP_OUT_LOG_MESSAGE\n",
		}))
		Expect(stream.PutCloudfoundryLogArgsForCall(1)).To(BeEquivalentTo(cloudfoundry.Log{
			Timestamp: time.Unix(0, log2.Timestamp).UTC(),
			Hostname:  "org.space.app",
			AppID:     appGUID,
			ProcessID: "[APP/1]",
			Message:   "APP_ERR_LOG_MESSAGE\n",
		}))
	})

	It("should handle logs with multi line structured data", func() {
		log := newAppLog(appGUID, "ping\n")
		log.Tags["some_weird_junk"] = "THIS\nSHOULD\nBE\nIGNORED"
		Expect(logs.Write(log)).To(Succeed())
	})

	It("should return 403 if attempt is made to inject log from another app", func() {
		log := newAppLog("E15DEE5C-FE32-47B4-91C4-C82D67F2FD4C", "UNAUTH_APP_ID")
		Expect(logs.Write(log)).To(MatchError(ContainSubstring("403 status code")))
	})
})

// newSyslogHTTPSWriter borrows some parts from loggregator to simulate how
// cloudfoundry logs are sent over http
func newSyslogHTTPSWriter(handlerURL, appGUID, secretKey string) egress.WriteCloser {
	drainURL, err := csls.NewSyslogDrainURL(handlerURL, appGUID, secretKey)
	if err != nil {
		panic(err)
	}
	url := &syslog.URLBinding{
		URL:      drainURL,
		AppID:    appGUID,
		Hostname: "org.space.app",
	}
	var netConf syslog.NetworkTimeoutConfig
	w := syslog.NewHTTPSWriter(
		url,
		netConf,
		&tls.Config{InsecureSkipVerify: true},
		&metricsHelpers.SpyMetric{},
	)
	return w
}

// newAppLog creates a loggregator_v2 log envelope to simulate the contents of
// a cloudfoundry log
func newAppLog(appGUID string, msg string) *loggregator_v2.Envelope {
	return &loggregator_v2.Envelope{
		Tags: map[string]string{
			"source_type": "APP",
		},
		InstanceId: "1",
		Timestamp:  time.Date(2001, time.January, 11, 11, 1, 1, 0, time.UTC).UnixNano(),
		SourceId:   appGUID,
		Message: &loggregator_v2.Envelope_Log{
			Log: &loggregator_v2.Log{
				Payload: []byte(msg),
				Type:    loggregator_v2.Log_OUT,
			},
		},
	}
}
