package csls

import (
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"os"

	"github.com/alphagov/tech-ops/cyber-security/components/csls-splunk-broker/pkg/cloudfoundry"
	uuid "github.com/satori/go.uuid"
)

const (
	ParamMAC               = "mac"
	ParamServiceInstanceID = "instance_id"
)

var (
	ErrUnauthorizedAppGUID    = fmt.Errorf("unauthorized-log-attempt")
	ErrUnauthenticatedRequest = fmt.Errorf("unauthenticated-request")
	ErrBadRequestBody         = fmt.Errorf("failed-to-read-body")
	ErrBadRequestParams       = fmt.Errorf("invalid-request-arguments")
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
	serviceInstanceGUID := uuid.FromStringOrNil(q.Get(ParamServiceInstanceID))
	if err := h.transformAndForwardLogEvent(r.Body, code, serviceInstanceGUID); err != nil {
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

// transformAndForwardLogEvent decodes a cloudfoundry format syslog line and
// forwards to kinesis with the service instance GUID as the logGroupName
func (h *Handler) transformAndForwardLogEvent(r io.Reader, code string, serviceInstanceGUID uuid.UUID) error {
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
	logGroupName := serviceInstanceGUID.String()
	// FIXME: Remove this "if" guard now!!!!!  Revert this commit!! We are
	// skipping verification on "old style" URL (ones without service instance
	// guid) to give us a chance to re-bind all the apps currently using the
	// log drain This should be removed in a follow up PR almost immediately,
	// if you are from the future and still seeing this here then that is BAD
	// and verification is broken.  This is fine before Pay are using it, they
	// are the team with the strict requirement around log tampering but
	// obviously nobody wants that
	if uuid.Equal(serviceInstanceGUID, uuid.Nil) {
		logGroupName = "rfc5424_syslog" // legacy
	} else {
		ok, _ := VerifyMAC(
			uuid.FromStringOrNil(log.AppID),
			serviceInstanceGUID,
			h.Secret,
			code,
		)
		if !ok {
			return ErrUnauthorizedAppGUID
		}
	}
	if err := h.Stream.PutCloudfoundryLog(log, logGroupName); err != nil {
		// TODO: log
		return ErrFailForwardStream
	}
	return nil
}
