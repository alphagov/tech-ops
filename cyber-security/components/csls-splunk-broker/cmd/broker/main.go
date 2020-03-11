package main

import (
	"fmt"
	"log"
	"os"

	"code.cloudfoundry.org/lager"
	"github.com/alphagov/paas-service-broker-base/broker"
	"github.com/alphagov/tech-ops/cyber-security/components/csls-splunk-broker/pkg/csls"
	"github.com/apex/gateway"
	"github.com/pivotal-cf/brokerapi/domain"
	"github.com/pivotal-cf/brokerapi/domain/apiresponses"
)

func MustGetEnv(k string) string {
	v := os.Getenv(k)
	if v == "" {
		panic(fmt.Sprintf("Environment variable %s is required", k))
	}
	return v
}

func run() error {
	drainURL := MustGetEnv("CSLS_ADAPTER_URL")
	secretKey := MustGetEnv("CSLS_HMAC_SECRET")

	config := broker.Config{
		API: broker.API{
			BasicAuthUsername: MustGetEnv("BROKER_USERNAME"),
			BasicAuthPassword: MustGetEnv("BROKER_PASSWORD"),
			LogLevel:          "DEBUG",
		},
		Catalog: broker.Catalog{
			Catalog: apiresponses.CatalogResponse{
				Services: []domain.Service{
					{
						ID:            "58f7243e-0b17-4e4d-8e24-0dac516fafd8",
						Name:          "splunk",
						Description:   "Log storage, analytics and protective monitoring by GDS Cyber Security",
						Bindable:      true,
						PlanUpdatable: false,
						Requires: []domain.RequiredPermission{
							domain.PermissionSyslogDrain,
						},
						Metadata: &domain.ServiceMetadata{
							DisplayName:         "splunk",
							ImageUrl:            "https://upload.wikimedia.org/wikipedia/commons/e/e8/Splunk-Logo.jpg",
							LongDescription:     "A centralised logging system provided by GDS Cyber Security",
							ProviderDisplayName: "GDS",
							DocumentationUrl:    "",
							SupportUrl:          "",
						},
						Plans: []domain.ServicePlan{
							{
								ID:          "4839b090-456c-4bb6-9e1d-f30824809328",
								Name:        "unlimited",
								Description: "unmetered usage for GDS tenants",
								Metadata: &domain.ServicePlanMetadata{
									DisplayName: "unlimited",
								},
							},
						},
					},
				},
			},
		},
	}

	logger := lager.NewLogger("splunk-service-broker")
	logger.RegisterSink(lager.NewWriterSink(os.Stdout, config.API.LagerLogLevel))

	splunkProvider, err := csls.NewSplunkProvider(drainURL, secretKey)
	if err != nil {
		return fmt.Errorf("Error creating splunk provider: %v\n", err)
	}

	serviceBroker, err := broker.New(config, splunkProvider, logger)
	if err != nil {
		return fmt.Errorf("Error creating service broker: %s", err)
	}

	brokerAPI := broker.NewAPI(serviceBroker, logger, config)

	fmt.Println("splunk service broker started on port " + config.API.Port + "...")
	return gateway.ListenAndServe(":3000", brokerAPI)
}

func main() {
	if err := run(); err != nil {
		log.Fatal(err)
	}
}
