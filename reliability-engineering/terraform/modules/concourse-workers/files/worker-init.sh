#!/usr/bin/env bash
set -ueo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update --yes

export AWS_REGION=eu-west-2
export AWS_DEFAULT_REGION=eu-west-2

echo "Installing dependences"
apt-get install --yes jq awscli

echo "Downloading concourse binaries"
concourse_archive="concourse-${concourse_version}-linux-amd64.tgz"
concourse_url="https://github.com/concourse/concourse/releases/download/v${concourse_version}/$concourse_archive"
cd /tmp
echo '${concourse_sha1}' > concourse.sha1
curl -L --silent --fail "$concourse_url" > "$concourse_archive"
sha1sum -c concourse.sha1
echo "Concourse binaries ok and pass checksum"
tar -xvf "$concourse_archive" -C /usr/local
cd -

echo "Configuring concourse"
mkdir -p /opt/concourse/keys
mkdir -p /opt/concourse/worker

aws ssm get-parameter \
  --name /${deployment}/concourse/worker/global/web_ssh_public_key \
  --with-decryption \
| jq -r .Parameter.Value > /opt/concourse/keys/web_pub_key

aws ssm get-parameter \
  --name /${deployment}/concourse/worker/global/ssh_key \
  --with-decryption \
| jq -r .Parameter.Value > /opt/concourse/keys/ssh_key

cat <<EOF > /etc/systemd/system/concourse-worker.service
[Unit]
Description=concourse-worker
After=network.target

[Service]
ExecStart=/usr/local/concourse/bin/concourse worker \
  --work-dir /opt/concourse/worker \
  --tsa-host ${concourse_host}:2222 \
  --tsa-public-key /opt/concourse/keys/web_pub_key \
  --tsa-worker-private-key /opt/concourse/keys/ssh_key \
  --ephemeral --baggageclaim-driver=overlay
Environment=CONCOURSE_GARDEN_DNS_SERVER=169.254.169.253
Type=simple
RestartSec=3s
Restart=always
KillSignal=SIGUSR2
WorkingDirectory=/opt/concourse/worker
TasksMax=infinity
MemoryLimit=infinity
LimitNPROC=infinity
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

# adapted from
# https://aws.amazon.com/blogs/compute/best-practices-for-handling-ec2-spot-instance-interruptions/
# 'EOF' in single quotes prevents varible interpolation; this is important
cat <<'EOF' > /usr/local/bin/check-spot-interruption
#!/bin/bash
set -ue
TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 1800"`

while sleep 5; do

    HTTP_CODE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s -w %%{http_code} -o /dev/null http://169.254.169.254/latest/meta-data/spot/instance-action)

    if [[ "$HTTP_CODE" -eq 401 ]] ; then
        echo 'Refreshing Authentication Token'
        TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 1800"`
    elif [[ "$HTTP_CODE" -eq 200 ]] ; then
        echo 'Interrupted: retiring concourse-worker'
        systemctl stop concourse-worker
        exit 0
    elif [[ "$HTTP_CODE" -eq 404 ]] ; then
        echo 'Not Interrupted'
    else
        echo "Unexpected http code $HTTP_CODE; exiting"
        exit 1
    fi
done
EOF
chmod +x /usr/local/bin/check-spot-interruption

cat <<EOF > /etc/systemd/system/check-spot-interruption.service
[Unit]
Description=Check EC2 metadata for spot interruption notices

[Service]
ExecStart=/usr/local/bin/check-spot-interruption
Type=simple
RestartSec=3s
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now concourse-worker
systemctl enable --now check-spot-interruption

# this enables the workers to talk to the internet
# see concourse/concourse #1667 and #2482
iptables -P FORWARD ACCEPT

apt-get install --yes prometheus-node-exporter
systemctl enable --now prometheus-node-exporter

## install cloudwatch log agent
curl -o /root/amazon-cloudwatch-agent.deb https://s3.amazonaws.com/amazoncloudwatch-agent/debian/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E /root/amazon-cloudwatch-agent.deb
usermod -aG adm cwagent

# configure which log files are shipped to cloudwatch
mkdir -p /opt/aws/amazon-cloudwatch-agent/etc/
cat <<EOF > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
	"agent": {
		"metrics_collection_interval": 60,
		"run_as_user": "cwagent"
	},
	"logs": {
		"logs_collected": {
			"files": {
				"collect_list": [
					{
						"file_path": "/var/log/syslog",
						"log_group_name": "${syslog_log_group_name}",
						"log_stream_name": "{hostname}/syslog"
					}
				]
			}
		}
	}
}
EOF

# start cloudwatch log agent
systemctl enable amazon-cloudwatch-agent.service
service amazon-cloudwatch-agent start
