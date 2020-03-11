package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/alphagov/tech-ops/cyber-security/components/csls-splunk-broker/pkg/aws"
	"github.com/alphagov/tech-ops/cyber-security/components/csls-splunk-broker/pkg/csls"
	"github.com/apex/gateway"
)

func MustGetEnv(k string) string {
	v := os.Getenv(k)
	if v == "" {
		panic(fmt.Sprintf("Environment variable %s is required", k))
	}
	return v
}

func run() error {
	client, err := aws.NewClient(&aws.Config{})
	if err != nil {
		return err
	}
	cslsClient, err := client.AssumeRole(MustGetEnv("CSLS_ROLE_ARN"))
	if err != nil {
		return err
	}
	handler := &csls.Handler{
		Secret: MustGetEnv("CSLS_HMAC_SECRET"),
		Stream: &csls.Stream{
			Name: MustGetEnv("CSLS_STREAM_NAME"),
			AWS:  cslsClient,
		},
	}
	if isRunningInCloudfoundry() {
		addr := fmt.Sprintf(":%s", os.Getenv("PORT"))
		fmt.Println("starting http server at", addr)
		return http.ListenAndServe(addr, handler)
	} else {
		addr := ":3000"
		fmt.Println("starting lambda server at", addr)
		return gateway.ListenAndServe(addr, handler)
	}
}

func isRunningInCloudfoundry() bool {
	return os.Getenv("PORT") != ""
}

func main() {
	if err := run(); err != nil {
		log.Fatal(err)
	}
}
