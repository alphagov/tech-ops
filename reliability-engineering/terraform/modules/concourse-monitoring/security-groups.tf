resource "aws_security_group" "concourse_monitoring_lb" {
  name        = "${var.deployment}-concourse-monitoring-lb"
  description = "${var.deployment}-concourse-monitoring-lb"
  vpc_id      = var.vpc_id

  tags = {
    Name       = "${var.deployment}-concourse-monitoring-lb"
    Deployment = var.deployment
  }
}

resource "aws_security_group" "concourse_grafana" {
  name        = "${var.deployment}-concourse-grafana"
  description = "${var.deployment}-concourse-grafana"
  vpc_id      = var.vpc_id

  tags = {
    Name       = "${var.deployment}-concourse-grafana"
    Deployment = var.deployment
  }
}

resource "aws_security_group" "concourse_grafana_db" {
  name        = "${var.deployment}-concourse-grafana-db"
  description = "${var.deployment}-concourse-grafana-db"
  vpc_id      = var.vpc_id

  tags = {
    Name       = "${var.deployment}-concourse-grafana-db"
    Deployment = var.deployment
  }
}

resource "aws_security_group_rule" "concourse_monitoring_lb_ingress_from_outside_443" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  security_group_id = aws_security_group.concourse_monitoring_lb.id
  cidr_blocks = concat(
    var.whitelisted_cidr_blocks,
    formatlist("%s/32", var.main_nat_gateway_egress_ips)
  )
}

resource "aws_security_group_rule" "concourse_monitoring_lb_ingress_from_outside_80" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 80
  to_port   = 80

  security_group_id = aws_security_group.concourse_monitoring_lb.id
  cidr_blocks       = var.whitelisted_cidr_blocks
}

module "concourse_monitoring_lb_can_talk_to_concourse_prometheus_over_9090" {
  source = "../sg-access-pair"

  source_sg_id      = aws_security_group.concourse_monitoring_lb.id
  destination_sg_id = var.prometheus_security_group_id
  from_port         = 9090
  to_port           = 9090
}

module "concourse_monitoring_lb_can_talk_to_concourse_grafana_over_3000" {
  source = "../sg-access-pair"

  source_sg_id      = aws_security_group.concourse_monitoring_lb.id
  destination_sg_id = aws_security_group.concourse_grafana.id
  from_port         = 3000
  to_port           = 3000
}

module "concourse_grafana_can_talk_to_concourse_prometheus_over_9090" {
  source = "../sg-access-pair"

  source_sg_id      = aws_security_group.concourse_grafana.id
  destination_sg_id = var.prometheus_security_group_id
  from_port         = 9090
  to_port           = 9090
}

module "concourse_grafana_can_talk_to_concourse_grafana_db_over_5432" {
  source = "../sg-access-pair"

  source_sg_id      = aws_security_group.concourse_grafana.id
  destination_sg_id = aws_security_group.concourse_grafana_db.id
  from_port         = 5432
  to_port           = 5432
}

resource "aws_security_group_rule" "concourse_grafana_egress_to_internet" {
  type      = "egress"
  protocol  = "tcp"
  from_port = 0
  to_port   = 65535

  security_group_id = aws_security_group.concourse_grafana.id
  cidr_blocks       = ["0.0.0.0/0"]
}

module "concourse_prometheus_can_scrape_metrics_from_concourse_grafana" {
  source = "../sg-access-pair"

  source_sg_id      = var.prometheus_security_group_id
  destination_sg_id = aws_security_group.concourse_grafana.id
  from_port         = 3000
  to_port           = 3000
}

module "concourse_prometheus_can_talk_to_concourse_grafana_over_9100" {
  source = "../sg-access-pair"

  source_sg_id      = var.prometheus_security_group_id
  destination_sg_id = aws_security_group.concourse_grafana.id
  from_port         = 9100
  to_port           = 9100
}

module "concourse_prometheus_can_talk_to_concourse_prometheus_over_9090" {
  source = "../sg-access-pair"

  source_sg_id      = var.prometheus_security_group_id
  destination_sg_id = var.prometheus_security_group_id
  from_port         = 9090
  to_port           = 9090
}

module "concourse_prometheus_can_talk_to_concourse_prometheus_node_exporter_over_9100" {
  source = "../sg-access-pair"

  source_sg_id      = var.prometheus_security_group_id
  destination_sg_id = var.prometheus_security_group_id
  from_port         = 9100
  to_port           = 9100
}
