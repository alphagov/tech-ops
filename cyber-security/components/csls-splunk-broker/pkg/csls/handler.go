package csls

import (
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"os"

	"github.com/alphagov/tech-ops/cyber-security/components/csls-splunk-broker/pkg/cloudfoundry"
)

const (
	ParamMAC               = "mac"
	ParamServiceInstanceID = "instance_id"
)

var (
	ErrUnauthorizedAppGUID    = fmt.Errorf("unauthorized-log-attempt")
	ErrUnauthenticatedRequest = fmt.Errorf("unauthenticated-request")
	ErrBadRequestBody         = fmt.Errorf("failed-to-read-body")
	ErrFailForwardStream      = fmt.Errorf("failed-to-forward-to-stream")
)

type Handler struct {
	// Stream is the log destination
	Stream CloudfoundryLogPutter
	// Secret is the shared secret for authenticating log requests
	Secret string
}

// HandleHTTP processes syslog over https from a standard go http.Server
func (h *Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	defer r.Body.Close()
	q := r.URL.Query()
	code := q.Get(ParamMAC)
	serviceInstanceGUID := q.Get(ParamServiceInstanceID)
	if err := h.process(r.Body, code, serviceInstanceGUID); err != nil {
		switch err {
		case ErrUnauthorizedAppGUID:
			w.WriteHeader(http.StatusForbidden)
			fmt.Fprintf(os.Stderr, "AUTH_ERROR: %s\n", err)
			fmt.Fprintln(w, "AUTH_ERROR")
		case ErrUnauthenticatedRequest:
			w.WriteHeader(http.StatusUnauthorized)
			fmt.Fprintf(os.Stderr, "AUTH_ERROR: %s\n", err)
			fmt.Fprintln(w, "AUTH_ERROR")
		case ErrBadRequestBody:
			w.WriteHeader(http.StatusBadRequest)
			fmt.Fprintf(os.Stderr, "BAD_REQUEST: %s\n", err)
			fmt.Fprintln(w, "BAD_REQUEST")
		case ErrFailForwardStream:
			w.WriteHeader(http.StatusServiceUnavailable) // close enough
			fmt.Fprintf(os.Stderr, "UPSTREAM_UNAVAILABLE: %s\n", err)
			fmt.Fprintln(w, "UPSTREAM_UNAVAILABLE")
		default:
			w.WriteHeader(http.StatusInternalServerError) // TODO: get error codes from errs not just 500 all the time
			fmt.Fprintf(os.Stderr, "FATAL: %s\n", err)
			fmt.Fprintln(w, "FATAL")
		}
		return
	}
	fmt.Fprintln(w, "OK")
}

// process decodes a cloudfoundry format syslog line and forward it to kinesis
// stream with the service instance GUID as the log group name
func (h *Handler) process(r io.Reader, code, serviceInstanceGUID string) error {
	b, err := ioutil.ReadAll(r)
	if err != nil {
		// TODO: log
		return ErrBadRequestBody
	}
	var log cloudfoundry.Log
	if err := cloudfoundry.UnmarshalRFC5424(b, &log); err != nil {
		// TODO: log
		return ErrBadRequestBody
	}
	ok, _ := VerifyMAC(
		log.AppID,
		serviceInstanceGUID,
		h.Secret,
		code,
	)
	if !ok {
		return ErrUnauthorizedAppGUID
	}
	if err := h.Stream.PutCloudfoundryLog(log, serviceInstanceGUID); err != nil {
		// TODO: log
		return ErrFailForwardStream
	}
	return nil
}
