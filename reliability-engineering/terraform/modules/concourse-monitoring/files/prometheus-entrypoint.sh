#!/bin/sh

set -euo pipefail

handle_term()
{
    echo "caught TERM signal; handling..."
    kill -TERM "${pid}"
    echo "end of TERM signal handling"
}

prep_prometheus()
{
    echo ${CONFIG_BASE64} | base64 -d  > /etc/prometheus/prometheus.yml
}

trap 'handle_term' TERM INT
prep_prometheus
prometheus --config.file=/etc/prometheus/prometheus.yml \
           --storage.tsdb.path=/opt/data \
           --web.console.libraries=/usr/share/prometheus/console_libraries \
           --web.console.templates=/usr/share/prometheus/consoles \
           --web.enable-lifecycle \
           &
pid=$!
wait ${pid}
echo "end of entrypoint.sh"
