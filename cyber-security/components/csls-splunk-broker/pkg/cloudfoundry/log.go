package cloudfoundry

import (
	"fmt"
	"time"

	rfc5424 "github.com/influxdata/go-syslog/v3/rfc5424"
)

// Log represents a single log line from a cloudfoundry application
type Log struct {
	Timestamp time.Time
	Hostname  string
	AppID     string
	ProcessID string
	Message   string
}

// UnmarshalRFC5424 reads bytes containing syslog (RFC5424) data and
// populates the given Log with data found
func UnmarshalRFC5424(b []byte, log *Log) error {
	m, err := rfc5424.NewParser().Parse(b)
	if err != nil {
		return fmt.Errorf("failed-to-parse-rfc5424: %s", err)
	}
	msg, ok := m.(*rfc5424.SyslogMessage)
	if !ok {
		return fmt.Errorf("failed-to-parse-rfc5424-bad-type")
	}
	if msg == nil {
		return fmt.Errorf("failed-to-parse-rfc5424-nil-message")
	}
	if msg.Message != nil {
		log.Message = *(msg.Message)
	}
	if msg.Hostname != nil {
		log.Hostname = *(msg.Hostname)
	}
	if msg.Appname != nil {
		log.AppID = *(msg.Appname)
	}
	if msg.ProcID != nil {
		log.ProcessID = *(msg.ProcID)
	}
	if msg.Timestamp != nil {
		log.Timestamp = (*(msg.Timestamp)).UTC()
	}
	return nil
}
