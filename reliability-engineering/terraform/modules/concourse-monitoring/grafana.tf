resource "aws_kms_key" "concourse_grafana" {
  description = "${var.deployment} concourse grafana"
}

resource "aws_kms_alias" "concourse_grafana" {
  name          = "alias/${var.deployment}-concourse-grafana"
  target_key_id = aws_kms_key.concourse_grafana.key_id
}

resource "random_string" "concourse_grafana_db_password" {
  length  = 64
  special = false
}

resource "aws_ssm_parameter" "concourse_grafana_db_password" {
  name   = "/${var.deployment}/grafana/db-password"
  type   = "SecureString"
  key_id = aws_kms_key.concourse_grafana.key_id
  value  = random_string.concourse_grafana_db_password.result
}

resource "random_string" "concourse_grafana_admin_password" {
  length  = 32
  special = false
}

resource "aws_ssm_parameter" "concourse_grafana_admin_password" {
  name   = "/${var.deployment}/grafana/grafana-admin-password"
  type   = "SecureString"
  key_id = aws_kms_key.concourse_grafana.key_id
  value  = random_string.concourse_grafana_admin_password.result
}

resource "aws_db_subnet_group" "concourse_grafana_db" {
  name       = "${var.deployment}-concourse-grafana-db"
  subnet_ids = var.private_subnet_ids
}

resource "aws_db_instance" "concourse_grafana_db" {
  identifier                = "${var.deployment}-concourse-grafana"
  allocated_storage         = 25
  storage_type              = "gp2"
  engine                    = "postgres"
  engine_version            = "10.10"
  instance_class            = "db.t2.small"
  name                      = "grafana"
  username                  = "grafana"
  password                  = random_string.concourse_grafana_db_password.result
  vpc_security_group_ids    = [aws_security_group.concourse_grafana_db.id]
  db_subnet_group_name      = aws_db_subnet_group.concourse_grafana_db.name
  final_snapshot_identifier = "${var.deployment}-concourse-grafana-final"
  backup_retention_period   = 7
  storage_encrypted         = true
  ca_cert_identifier        = "rds-ca-2019"
}

data "template_file" "concourse_grafana_container_def" {
  template = file("${path.module}/files/grafana-container-def.json")

  vars = {
    deployment                   = var.deployment
    grafana_url                  = local.grafana_url
    database_host                = aws_db_instance.concourse_grafana_db.endpoint
    aws_account_id               = data.aws_caller_identity.account.account_id
    github_allowed_organizations = join(",", var.grafana_github_allowed_organizations)
  }
}

resource "aws_ecs_task_definition" "concourse_grafana_task_def" {
  family                   = "${var.deployment}-concourse-grafana"
  container_definitions    = data.template_file.concourse_grafana_container_def.rendered
  execution_role_arn       = aws_iam_role.concourse_grafana_execution.arn
  network_mode             = "awsvpc"
  cpu                      = 2048
  memory                   = 4096
  requires_compatibilities = ["FARGATE"]
}

resource "aws_ecs_service" "concourse_grafana" {
  name            = "${var.deployment}-concourse-grafana"
  cluster         = aws_ecs_cluster.concourse_grafana.name
  task_definition = aws_ecs_task_definition.concourse_grafana_task_def.arn
  launch_type     = "FARGATE"

  desired_count                      = 1
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  load_balancer {
    target_group_arn = aws_lb_target_group.concourse_grafana.id
    container_name   = "grafana"
    container_port   = "3000"
  }

  network_configuration {
    security_groups = [aws_security_group.concourse_grafana.id]
    subnets         = var.private_subnet_ids
  }

  service_registries {
    registry_arn = aws_service_discovery_service.grafana_service_discovery.arn
    port         = 3000
  }
}

resource "aws_service_discovery_private_dns_namespace" "monitoring_apps" {
  name        = "monitoring.local"
  description = "Monitoring app instances"
  vpc         = var.vpc_id
}

resource "aws_service_discovery_service" "grafana_service_discovery" {
  name = "${var.deployment}-concourse-grafana"

  description = "Service discovery for ${var.deployment}-concourse-grafana instances"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.monitoring_apps.id

    dns_records {
      ttl  = 60
      type = "SRV"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 2
  }
}

provider "grafana" {
  url  = "https://grafana.${local.monitoring_domain}"
  auth = "admin:${random_string.concourse_grafana_admin_password.result}"
}

resource "grafana_data_source" "prom_data_source" {
  count      = 2
  is_default = element([true, false], count.index)
  type       = "prometheus"
  name       = "Prometheus ${count.index + 1}"
  url        = "http://prom-${count.index + 1}.${data.aws_route53_zone.private_root.name}:9090"
}

locals {
  grafana_dashboards = [
    "alerts",
    "concourse",
    "metrics-by-team"
  ]
}
resource "grafana_dashboard" "metrics" {
  for_each    = toset(local.grafana_dashboards)
  config_json = file("${path.module}/files/dashboards/${each.key}.json")
  depends_on  = [grafana_data_source.prom_data_source[0]]
}
