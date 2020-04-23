package csls

import (
	"context"
	"errors"
	"fmt"
	"net/url"
	"strings"

	provideriface "github.com/alphagov/paas-service-broker-base/provider"
	"github.com/pivotal-cf/brokerapi"
	"github.com/pivotal-cf/brokerapi/domain"
	uuid "github.com/satori/go.uuid"
)

type SplunkProvider struct {
	SyslogDrainURL string
	SecretKey      string
}

func NewSplunkProvider(drainURL, secretKey string) (*SplunkProvider, error) {
	if !strings.HasPrefix(drainURL, "https://") {
		return nil, fmt.Errorf("invalid-syslog-drain-url")
	}
	if len(secretKey) < 16 {
		return nil, fmt.Errorf("secret-too-short")
	}
	_, err := url.Parse(drainURL)
	if err != nil {
		return nil, err
	}
	return &SplunkProvider{
		SyslogDrainURL: drainURL,
		SecretKey:      secretKey,
	}, nil
}

func (s *SplunkProvider) Provision(ctx context.Context, provisionData provideriface.ProvisionData) (dashboardURL, operationData string, isAsync bool, err error) {
	// no-op or maybe provision an index based on provisionData.Details.ServiceID
	return "", "", false, err
}

func (s *SplunkProvider) Deprovision(ctx context.Context, deprovisionData provideriface.DeprovisionData) (operationData string, isAsync bool, err error) {
	// no-op or maybe delete an index? (probably don't really want to do that!)
	return "", false, err
}

func (s *SplunkProvider) Bind(ctx context.Context, bindData provideriface.BindData) (binding domain.Binding, err error) {
	// generate a signed url that only works for this app id or service id if per index
	drainURL, err := NewSyslogDrainURL(
		s.SyslogDrainURL,
		bindData.Details.AppGUID,
		bindData.InstanceID,
		s.SecretKey,
	)
	if err != nil {
		return domain.Binding{}, err // TODO: this should be 403 or 400
	}
	return domain.Binding{
		IsAsync:        false,
		SyslogDrainURL: drainURL.String(),
	}, nil
}

func (s *SplunkProvider) Unbind(ctx context.Context, unbindData provideriface.UnbindData) (domain.UnbindSpec, error) {
	// no op
	return domain.UnbindSpec{
		IsAsync: false,
	}, nil
}

var ErrUpdateNotSupported = errors.New("Updating a splunk service is currently not supported")

func (s *SplunkProvider) Update(ctx context.Context, updateData provideriface.UpdateData) (
	operationData string, isAsync bool, err error) {
	return "", false, ErrUpdateNotSupported
}

func (s *SplunkProvider) LastOperation(ctx context.Context, lastOperationData provideriface.LastOperationData) (state domain.LastOperationState, description string, err error) {
	return brokerapi.Succeeded, "Last operation polling not required. All operations are synchronous.", nil
}

func NewSyslogDrainURL(baseURL, appID, instanceID, secretKey string) (*url.URL, error) {
	u, err := url.Parse(baseURL)
	if err != nil {
		return nil, err
	}
	appGUID, err := uuid.FromString(appID)
	if err != nil {
		return nil, err
	}
	instanceGUID, err := uuid.FromString(instanceID)
	if err != nil {
		return nil, err
	}
	code, err := GenerateMAC(
		appGUID,
		instanceGUID,
		secretKey,
	)
	if err != nil {
		return nil, err
	}
	q := u.Query()
	q.Add(ParamMAC, code)
	q.Add(ParamServiceInstanceID, instanceID)
	u.RawQuery = q.Encode()
	return u, nil
}
