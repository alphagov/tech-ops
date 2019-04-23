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
  concourse_tsa_team_key_args="$concourse_tsa_team_key_args --tsa-team-authorized-keys=$team_name=$team_key_file_path"
done

cat <<EOF > /etc/systemd/system/concourse-web.service
[Unit]
Description=concourse-web
After=network.target

[Service]
ExecStart=/usr/local/bin/concourse web \
  \
  --tsa-authorized-keys /dev/null                       \
  $concourse_tsa_team_key_args                          \
  --tsa-host-key        /opt/concourse/keys/web_ssh     \
  --session-signing-key /opt/concourse/keys/web_session \
  \
  --external-url https://${concourse_external_url} \
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
  --peer-url http://$${local_ip}:8080 \
  \
  --add-local-user ${local_users} \

Type=simple
RestartSec=3s
Restart=always
WorkingDirectory=/opt/concourse/web
TasksMax=infinity
MemoryLimit=infinity
LimitNPROC=infinity
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable concourse-web
systemctl start  concourse-web

apt-get install prometheus-node-exporter
systemctl enable prometheus-node-exporter
systemctl start prometheus-node-exporter
