## Domain information

This domain used to contain information about domains but all the content has since been moved. We leave this site on the old domain to redirect people to the correct information.

### Deploy

This is deployed as a staticfile app on PaaS:
Region: Ireland
Org: gds-tech-ops
Space: domaininformation

To deploy it you will need access to the above org/space and a cf-cli version >=7.0.0, then:
```
cf7 push --strategy rolling domaininformation --var deployed-by="${USER}s-laptop" --var current-datetime="$(date -u '+%Y-%m-%d')"
```

### DNS

DNS is managed in alphagov/govuk-dns-config in the service.gov.uk zone. You will need a DNS admin to deploy any changes.
