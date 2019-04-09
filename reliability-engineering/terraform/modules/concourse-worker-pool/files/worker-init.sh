#!/usr/bin/env bash
set -ueo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update --yes

export AWS_REGION=eu-west-2
export AWS_DEFAULT_REGION=eu-west-2

echo "Installing dependences"
apt-get install --yes jq awscli

echo "Downloading concourse binaries"
concourse_url="https://github.com/concourse/concourse/releases/download/${concourse_version}/concourse_linux_amd64"
cd /tmp
echo '${concourse_sha1}' > concourse_linux_amd64.sha1
curl -L --silent --fail "$concourse_url" > concourse_linux_amd64
sha1sum -c concourse_linux_amd64.sha1
echo "Concourse binaries ok and pass checksum"
cd -
mv /tmp/concourse_linux_amd64 /usr/local/bin/concourse
chmod +x /usr/local/bin/concourse

echo "Configuring concourse"
mkdir -p /opt/concourse/keys
mkdir -p /opt/concourse/worker

aws ssm get-parameter \
  --name /${deployment}/concourse/worker/${worker_team_name}/web_ssh_public_key \
  --with-decryption \
| jq -r .Parameter.Value > /opt/concourse/keys/web_pub_key

aws ssm get-parameter \
  --name /${deployment}/concourse/worker/${worker_team_name}/ssh_key \
  --with-decryption \
| jq -r .Parameter.Value > /opt/concourse/keys/ssh_key

cat <<EOF > /etc/systemd/system/concourse-worker.service
[Unit]
Description=concourse-worker
After=network.target

[Service]
ExecStart=/usr/local/bin/concourse worker \
  --work-dir /opt/concourse/worker \
  --tsa-host ${concourse_host}:2222 \
  --tsa-public-key /opt/concourse/keys/web_pub_key \
  --tsa-worker-private-key /opt/concourse/keys/ssh_key \
  --garden-dns-server 169.254.169.253 \
  --ephemeral --baggageclaim-driver=overlay \
  --team ${worker_team_name}
Type=simple
RestartSec=3s
Restart=always
WorkingDirectory=/opt/concourse/worker
TasksMax=infinity
MemoryLimit=infinity
LimitNPROC=infinity
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable concourse-worker
systemctl start  concourse-worker

# this enables the workers to talk to the internet
# see concourse/concourse #1667 and #2482
iptables -P FORWARD ACCEPT

apt-get install prometheus-node-exporter
systemctl enable prometheus-node-exporter
systemctl start prometheus-node-exporter
