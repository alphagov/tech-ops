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
mkdir -p /opt/concourse/web

github_client_id="$(
  aws ssm get-parameter \
    --name /${deployment}/concourse/web/github_client_id \
    --with-decryption \
  | jq -r .Parameter.Value
)"
github_client_secret="$(
  aws ssm get-parameter \
    --name /${deployment}/concourse/web/github_client_secret \
    --with-decryption \
  | jq -r .Parameter.Value
)"
postgres_password="$(
  aws ssm get-parameter \
    --name /${deployment}/concourse/web/db_password \
    --with-decryption \
  | jq -r .Parameter.Value
)"
local_users="$(
  aws ssm get-parameter \
    --name /${deployment}/concourse/web/local_users \
    --with-decryption \
  | jq -r .Parameter.Value
)"

aws ssm get-parameter \
  --name /${deployment}/concourse/web/ssh_key \
  --with-decryption \
| jq -r .Parameter.Value > /opt/concourse/keys/web_ssh

aws ssm get-parameter \
  --name /${deployment}/concourse/web/session_key \
  --with-decryption \
| jq -r .Parameter.Value > /opt/concourse/keys/web_session

local_ip="$(curl -sf http://169.254.169.254/latest/meta-data/local-ipv4)"

team_keys="$(aws s3 cp \
             s3://${concourse_web_bucket}/${worker_keys_s3_object_key} -)"
concourse_tsa_team_key_args=""
for team_name in $(jq -r 'keys | join("\n")' <<< "$team_keys"); do
  team_key_file_path="/opt/concourse/keys/worker_$team_name"
  team_key_file_contents="$(jq -r ".[\"$team_name\"]" <<< "$team_keys")"

  echo "Writing team_key_file for $team_name to $team_key_file_path"
  echo "$team_key_file_contents" > "$team_key_file_path"
  concourse_tsa_team_key_args="$concourse_tsa_team_key_args --tsa-team-authorized-keys=$team_name:$team_key_file_path"
done

cat <<EOF > /etc/systemd/system/concourse-web.service
[Unit]
Description=concourse-web
After=network.target

[Service]
ExecStart=/usr/local/concourse/bin/concourse web \
  \
  --tsa-authorized-keys /dev/null                       \
  $concourse_tsa_team_key_args                          \
  --tsa-host-key        /opt/concourse/keys/web_ssh     \
  --session-signing-key /opt/concourse/keys/web_session \
  \
  --external-url https://${concourse_external_url} \
  --peer-address $${local_ip}                      \
  \
  --aws-ssm-region eu-west-2 \
  --aws-ssm-pipeline-secret-template \
    /${deployment}/concourse/pipelines/{{.Team}}/{{.Pipeline}}/{{.Secret}} \
  --aws-ssm-team-secret-template \
    /${deployment}/concourse/pipelines/{{.Team}}/{{.Secret}} \
  \
  --postgres-database concourse             \
  --postgres-user     concourse             \
  --postgres-host     ${concourse_db_url}   \
  --postgres-password $${postgres_password} \
  \
  --github-client-id      $${github_client_id}     \
  --github-client-secret  $${github_client_secret} \
  --main-team-github-team ${main_team_github_team} \
  \
  --prometheus-bind-ip   0.0.0.0 \
  --prometheus-bind-port 9391    \
  \
  \
  $(jq -r 'to_entries | map("--add-local-user \(.key):\(.value)") | join(" ")' <<< $local_users) \
  --main-team-local-user=main \

Type=simple
RestartSec=3s
Restart=always
WorkingDirectory=/opt/concourse/web
TasksMax=infinity
MemoryLimit=infinity
LimitNPROC=infinity
LimitNOFILE=infinity

Environment=CONCOURSE_SECRET_CACHE_ENABLED=true
Environment=CONCOURSE_SECRET_CACHE_DURATION=5m
Environment=CONCOURSE_ENABLE_BUILD_AUDITING=true
Environment=CONCOURSE_ENABLE_CONTAINER_AUDITING=true
Environment=CONCOURSE_ENABLE_JOB_AUDITING=true
Environment=CONCOURSE_ENABLE_PIPELINE_AUDITING=true
Environment=CONCOURSE_ENABLE_RESOURCE_AUDITING=true
Environment=CONCOURSE_ENABLE_SYSTEM_AUDITING=true
Environment=CONCOURSE_ENABLE_TEAM_AUDITING=true
Environment=CONCOURSE_ENABLE_WORKER_AUDITING=true
Environment=CONCOURSE_ENABLE_VOLUME_AUDITING=true
Environment=CONCOURSE_GC_FAILED_GRACE_PERIOD=1h

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable concourse-web
systemctl start  concourse-web

apt-get install prometheus-node-exporter
systemctl enable prometheus-node-exporter
systemctl start prometheus-node-exporter

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
						"log_group_name": "${concourse_web_syslog_log_group_name}",
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
