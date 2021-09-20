#!/usr/bin/env bash
set -ueo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update --yes
apt-get upgrade --yes

export AWS_REGION=eu-west-2
export AWS_DEFAULT_REGION=eu-west-2

# Create a swapfile
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

# Guard against Prometheus crashing because of a /etc/resolv.conf
# parsing issue https://github.com/miekg/dns/pull/642
rm /etc/resolv.conf
sed -e 's/ trust-ad//' < /run/systemd/resolve/stub-resolv.conf > /etc/resolv.conf

echo 'Configuring prometheus EBS'
vol=""
while [ -z "$vol" ]; do
  # adapted from
  # https://medium.com/@moonape1226/mount-aws-ebs-on-ec2-automatically-with-cloud-init-e5e837e5438a
  # [Last accessed on 2020-04-02]
  vol=$(lsblk | grep -e disk | awk '{sub("G","",$4)} {if ($4+0 == ${data_volume_size}) print $1}')
  echo "still waiting for data volume ; sleeping 5"
  sleep 5
done
mkdir -p /var/lib/prometheus
echo "found volume /dev/$vol"
if [ -z "$(lsblk | grep "$vol" | awk '{print $7}')" ] ; then
  if [ -z "$(blkid /dev/$vol | grep ext4)" ] ; then
    echo "volume /dev/$vol is not formatted ; formatting"
    mkfs -F -t ext4 "/dev/$vol"
  else
    echo "volume /dev/$vol is already formatted"
  fi

  echo "volume /dev/$vol is not mounted ; mounting"
  mount "/dev/$vol" /var/lib/prometheus
  UUID=$(blkid /dev/$vol -s UUID -o value)
  if [ -z "$(grep $UUID /etc/fstab)" ] ; then
    echo "writing fstab entry"

    echo "UUID=$UUID /var/lib/prometheus ext4 defaults,nofail 0 2" >> /etc/fstab
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
      - source_labels: [__meta_ec2_tag_Deployment]
        regex: '${deployment}'
        action: keep
      - source_labels: [__meta_ec2_tag_Role]
        regex: 'prometheus'
        action: keep
      - source_labels: [__meta_ec2_instance_id]
        target_label: instance

  - job_name: concourse_grafana
    metrics_path: '/metrics'
    scheme: 'http'
    dns_sd_configs:
      - names:
          - "${deployment}-concourse-grafana.local.cd.gds-reliability.engineering"
    relabel_configs:
      - source_labels: [__meta_dns_name]
        target_label: job
        regex: "^${deployment}-concourse-(.*).local.cd.gds-reliability.engineering$"

  - job_name: concourse_node_exporter
    ec2_sd_configs:
      - region: eu-west-2
        refresh_interval: 30s
        port: 9100
    relabel_configs:
      - source_labels: [__meta_ec2_tag_Deployment]
        regex: '${deployment}'
        action: keep
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
      - source_labels: [__meta_ec2_tag_Deployment]
        regex: '${deployment}'
        action: keep
      - source_labels: [__meta_ec2_tag_Role]
        regex: 'concourse-web'
        action: keep
      - source_labels: [__meta_ec2_instance_id]
        target_label: instance
EOF

# ensure that prometheus owns it's files after a ubuntu upgrade the "pollinate"
# user owned all the files (potentially some kind of issue with uid mismatch)
promvar="/var/lib/prometheus"
if [ -d $promvar ]; then
	chown -R prometheus:prometheus $promvar
fi

systemctl daemon-reload
systemctl enable prometheus

reboot
