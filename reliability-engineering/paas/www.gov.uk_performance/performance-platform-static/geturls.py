#!/usr/bin/env python3
items = """
about
services
web-traffic
other
prototypes
data/transaction-volumes.csv
"""
for item in items.splitlines():
    print(f'https://performance-platform-spotlight-live.cloudapps.digital/performance/{item}')

import requests
resp = requests.get('https://performance-platform-stagecraft-production.cloudapps.digital/public/dashboards')
assert resp.status_code == 200
for item in resp.json()['items']:
    dashboard = item['slug']
    print(f'https://performance-platform-spotlight-live.cloudapps.digital/performance/{dashboard}')
    resp = requests.get('https://performance-platform-stagecraft-production.cloudapps.digital/public/dashboards?slug={}'.format(dashboard))
    assert resp.status_code == 200
    for module in resp.json()['modules']:
        module_slug = module['slug']
        print(f'https://performance-platform-spotlight-live.cloudapps.digital/performance/{dashboard}/{module_slug}')
        for tab in module.get('tabs', []):
            tab_slug = tab['slug']
            print(f'https://performance-platform-spotlight-live.cloudapps.digital/performance/{dashboard}/{module_slug}/{module_slug}-{tab_slug}')

