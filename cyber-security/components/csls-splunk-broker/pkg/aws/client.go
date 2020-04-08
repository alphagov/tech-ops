package aws

import (
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/credentials/stscreds"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/kinesis"
	"github.com/aws/aws-sdk-go/service/sts"
)

type Config = aws.Config

//go:generate go run github.com/maxbrunsfeld/counterfeiter/v6 . Client

// Client is the set of AWS SDK APIs required
type Client interface {
	PutRecord(*kinesis.PutRecordInput) (*kinesis.PutRecordOutput, error)
	AssumeRole(string) (Client, error)
}

// client is a wrapper around AWS SDK Client exposing only the required API
// calls and no more. This allows for effective mocking of the client for testing.
type client struct {
	*kinesis.Kinesis
}

// NewClient creates a new AWS SDK client configured from the environment
func NewClient(cfg *aws.Config) (Client, error) {
	if cfg == nil {
		cfg = &aws.Config{}
	}
	s, err := session.NewSession(cfg)
	if err != nil {
		return nil, err
	}
	c := &client{}
	c.Kinesis = kinesis.New(s)
	return c, nil
}

func (c *client) AssumeRole(roleARN string) (Client, error) {
	sess := session.Must(session.NewSessionWithOptions(session.Options{
		SharedConfigState: session.SharedConfigEnable,
	}))
	cfg := &aws.Config{
		Credentials: credentials.NewCredentials(&stscreds.AssumeRoleProvider{
			Client:   sts.New(sess),
			RoleARN:  roleARN,
			Duration: stscreds.DefaultDuration,
		}),
	}
	return NewClient(cfg)
}
