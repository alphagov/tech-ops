# Used for HTTP/HTTPS from outside
resource "aws_security_group" "concourse_lb" {
  name        = "${var.deployment}-concourse-lb"
  description = "${var.deployment}-concourse-lb"
  vpc_id      = var.vpc_id

  tags = {
    Name       = "${var.deployment}-concourse-lb"
    Deployment = var.deployment
  }
}

# Used for TCP from inside
resource "aws_security_group" "concourse_elb" {
  name        = "${var.deployment}-concourse-elb"
  description = "${var.deployment}-concourse-elb"
  vpc_id      = var.vpc_id

  tags = {
    Name       = "${var.deployment}-concourse-elb"
    Deployment = var.deployment
  }
}

resource "aws_security_group" "concourse_web" {
  name        = "${var.deployment}-concourse-web"
  description = "${var.deployment}-concourse-web"
  vpc_id      = var.vpc_id

  tags = {
    Name       = "${var.deployment}-concourse-web"
    Deployment = var.deployment
  }
}

resource "aws_security_group" "concourse_db" {
  name        = "${var.deployment}-concourse-db"
  description = "${var.deployment}-concourse-db"
  vpc_id      = var.vpc_id

  tags = {
    Name       = "${var.deployment}-concourse-db"
    Deployment = var.deployment
  }
}

resource "aws_security_group" "concourse_worker_base" {
  name        = "${var.deployment}-concourse-worker-base"
  description = "${var.deployment}-concourse-worker-base"
  vpc_id      = var.vpc_id

  tags = {
    Name       = "${var.deployment}-concourse-worker-base"
    Deployment = var.deployment
  }
}

resource "aws_security_group" "concourse_prometheus" {
  name        = "${var.deployment}-concourse-prometheus"
  description = "${var.deployment}-concourse-prometheus"
  vpc_id      = var.vpc_id

  tags = {
    Name       = "${var.deployment}-concourse-prometheus"
    Deployment = var.deployment
  }
}

output "concourse_worker_base_sg_id" {
  value = aws_security_group.concourse_worker_base.id
}

output "concourse_prometheus_sg_id" {
  value = aws_security_group.concourse_prometheus.id
}

resource "aws_security_group_rule" "concourse_lb_ingress_from_outside_2222" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 2222
  to_port   = 2222

  security_group_id = aws_security_group.concourse_lb.id
  cidr_blocks       = var.whitelisted_cidr_blocks
}

resource "aws_security_group_rule" "concourse_lb_ingress_from_outside_443" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  security_group_id = aws_security_group.concourse_lb.id
  cidr_blocks       = var.whitelisted_cidr_blocks
}

resource "aws_security_group_rule" "concourse_lb_ingress_from_outside_80" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 80
  to_port   = 80

  security_group_id = aws_security_group.concourse_lb.id
  cidr_blocks       = var.whitelisted_cidr_blocks
}

resource "aws_security_group_rule" "concourse_lb_ingress_from_workers_443" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  security_group_id = aws_security_group.concourse_lb.id
  cidr_blocks       = formatlist("%s/32", var.worker_pool_egress_eips)
}

resource "aws_security_group_rule" "concourse_web_egress_to_outside" {
  type      = "egress"
  protocol  = "all"
  from_port = 0
  to_port   = 65535

  security_group_id = aws_security_group.concourse_web.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "concourse_worker_base_egress_to_outside" {
  type      = "egress"
  protocol  = "all"
  from_port = 0
  to_port   = 65535

  security_group_id = aws_security_group.concourse_worker_base.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "concourse_prometheus_egress_to_outside" {
  type      = "egress"
  protocol  = "all"
  from_port = 0
  to_port   = 65535

  security_group_id = aws_security_group.concourse_prometheus.id
  cidr_blocks       = ["0.0.0.0/0"]
}

module "concourse_lb_can_talk_to_concourse_web" {
  source = "../sg-access-pair"

  source_sg_id      = aws_security_group.concourse_lb.id
  destination_sg_id = aws_security_group.concourse_web.id
  from_port         = 0
  to_port           = 65535
}

module "concourse_elb_can_talk_to_concourse_web" {
  source = "../sg-access-pair"

  source_sg_id      = aws_security_group.concourse_elb.id
  destination_sg_id = aws_security_group.concourse_web.id
  from_port         = 0
  to_port           = 65535
}

module "concourse_web_can_talk_to_concourse_db" {
  source = "../sg-access-pair"

  source_sg_id      = aws_security_group.concourse_web.id
  destination_sg_id = aws_security_group.concourse_db.id
  from_port         = 0
  to_port           = 65535
}

module "concourse_web_can_talk_to_concourse_web" {
  source = "../sg-access-pair"

  source_sg_id      = aws_security_group.concourse_web.id
  destination_sg_id = aws_security_group.concourse_web.id
  from_port         = 0
  to_port           = 65535
}

module "concourse_web_can_talk_to_concourse_worker_base" {
  source = "../sg-access-pair"

  source_sg_id      = aws_security_group.concourse_web.id
  destination_sg_id = aws_security_group.concourse_worker_base.id
  from_port         = 0
  to_port           = 65535
}

module "concourse_worker_base_can_talk_to_concourse_elb_over_2222" {
  source = "../sg-access-pair"

  source_sg_id      = aws_security_group.concourse_worker_base.id
  destination_sg_id = aws_security_group.concourse_elb.id
  from_port         = 0
  to_port           = 65535
}

module "concourse_prometheus_can_talk_to_concourse_web_over_9100" {
  source = "../sg-access-pair"

  source_sg_id      = aws_security_group.concourse_prometheus.id
  destination_sg_id = aws_security_group.concourse_web.id
  from_port         = 9100
  to_port           = 9100
}

module "concourse_prometheus_can_talk_to_concourse_web_over_9391" {
  source = "../sg-access-pair"

  source_sg_id      = aws_security_group.concourse_prometheus.id
  destination_sg_id = aws_security_group.concourse_web.id
  from_port         = 9391
  to_port           = 9391
}

module "concourse_prometheus_can_talk_to_concourse_worker_base_over_9100" {
  source = "../sg-access-pair"

  source_sg_id      = aws_security_group.concourse_prometheus.id
  destination_sg_id = aws_security_group.concourse_worker_base.id
  from_port         = 9100
  to_port           = 9100
}
