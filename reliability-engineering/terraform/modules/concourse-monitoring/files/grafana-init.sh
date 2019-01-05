#!/usr/bin/env bash
set -ueo pipefail

apt-get update  --yes
apt-get upgrade --yes

export AWS_REGION=eu-west-2
export AWS_DEFAULT_REGION=eu-west-2

echo 'Installing and configuring docker'
apt-get install --yes docker.io
mkdir -p /etc/systemd/system/docker.service.d
cat <<EOF > /etc/systemd/system/docker.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --dns ${vpc_dns_resolver}
EOF
systemctl stop docker
systemctl daemon-reload
systemctl enable docker
systemctl restart docker

echo 'Running ECS using Docker'
mkdir -p /etc/ecs
mkdir -p /var/lib/ecs/data

docker run \
  --init \
  --privileged \
  --name ecs-agent \
  --detach=true \
  --restart=on-failure:10 \
  --volume=/etc/ecs:/etc/ecs \
  --volume=/lib64:/lib64 \
  --volume=/lib:/lib \
  --volume=/proc:/host/proc \
  --volume=/sbin:/sbin \
  --volume=/sys/fs/cgroup:/sys/fs/cgroup \
  --volume=/usr/lib:/usr/lib \
  --volume=/var/lib/ecs/data:/data \
  --volume=/var/lib/ecs/dhclient:/var/lib/dhclient \
  --volume=/var/run:/var/run \
  --net=host \
  --env="ECS_CLUSTER=${deployment}-grafana" \
  --env=AWS_DEFAULT_REGION=eu-west-2 \
  --env=ECS_DATADIR=/data \
  --env=ECS_ENABLE_TASK_ENI=true \
  --env=ECS_ENABLE_TASK_IAM_ROLE=true \
  --env=ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true \
  --env="ECS_LOGLEVEL=warn" \
  amazon/amazon-ecs-agent:v1.23.0

apt-get install prometheus-node-exporter
systemctl enable prometheus-node-exporter
systemctl start prometheus-node-exporter
