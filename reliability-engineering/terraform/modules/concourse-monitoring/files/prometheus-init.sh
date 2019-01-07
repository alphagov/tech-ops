#!/usr/bin/env bash
set -ueo pipefail

apt-get update --yes
apt-get upgrade --yes

export AWS_REGION=eu-west-2
export AWS_DEFAULT_REGION=eu-west-2

vol="nvme1n1"

mkdir -p /var/lib/prometheus
while true; do
  lsblk | grep -q "$vol" && break
  echo "still waiting for volume /dev/$vol ; sleeping 5"
  sleep 5
done
echo "found volume /dev/$vol"
if [ -z "$(lsblk | grep "$vol" | awk '{print $7}')" ] ; then
  if file -s "/dev/$vol" | grep -q ": data" ; then
    echo "volume /dev/$vol is not formatted ; formatting"
    mkfs -F -t ext4   "/dev/$vol"
  fi
  echo "volume /dev/$vol is formatted"

  if [ -z "$(lsblk | grep "$vol" | awk '{print $7}')" ] ; then
    echo "volume /dev/$vol is not mounted ; mounting"
    mount "/dev/$vol" /var/lib/prometheus
  fi
    echo "volume /dev/$vol is mounted ; mounting"

  if grep -qv "/dev/$vol" /etc/fstab ; then
    echo "/dev/$vol /var/lib/prometheus ext4 defaults,nofail 0 2" >> /etc/fstab
  fi
fi

echo "Installing dependences"
apt-get install --yes jq awscli dnsutils prometheus

cat <<EOF > /etc/prometheus/prometheus.yml
global:
  scrape_interval:     15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: concourse_prometheus
    ec2_sd_configs:
      - region: eu-west-2
        refresh_interval: 30s
        port: 9090
    relabel_configs:
      - source_labels: [__meta_ec2_tag_Name]
        regex: '^${deployment}-concourse-prometheus$'
        action: keep
      - source_labels: [__meta_ec2_instance_id]
        target_label: instance

  - job_name: concourse_node_exporter
    ec2_sd_configs:
      - region: eu-west-2
        refresh_interval: 30s
        port: 9100
    relabel_configs:
      - source_labels: [__meta_ec2_instance_id]
        target_label: instance
      - source_labels: [__meta_ec2_tag_Role]
        target_label: role
      - source_labels: [__meta_ec2_tag_Team]
        target_label: team

  - job_name: concourse_web
    ec2_sd_configs:
      - region: eu-west-2
        refresh_interval: 30s
        port: 9391
    relabel_configs:
      - source_labels: [__meta_ec2_tag_Name]
        regex: '^${deployment}-concourse-web$'
        action: keep
      - source_labels: [__meta_ec2_instance_id]
        target_label: instance
EOF

systemctl daemon-reload
systemctl enable  prometheus
systemctl restart prometheus
