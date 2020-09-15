data "template_file" "concourse_prometheus_config" {
  template = file("${path.module}/files/prometheus.yml")

  vars = {
    deployment = var.deployment
  }
}

resource "aws_cloudwatch_log_group" "prometheus" {
  name = "${var.deployment}-prometheus"
}

locals {
  data_volume_name = "prometheus-data"
}

data "aws_region" "current" {}

data "template_file" "prometheus_task_definition" {
  template = file("${path.module}/files/prometheus-task-definition.json")
  vars = {
    data_volume_name             = local.data_volume_name
    log_group_name               = aws_cloudwatch_log_group.prometheus.name
    log_group_region             = data.aws_region.current.name
    config_base64                = base64encode(data.template_file.concourse_prometheus_config.rendered)
    prometheus_entrypoint_base64 = base64encode(file("${path.module}/files/prometheus-entrypoint.sh"))
  }
}

resource "aws_ecs_task_definition" "prometheus" {
  family                   = "${var.deployment}-prometheus"
  container_definitions    = data.template_file.prometheus_task_definition.rendered
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  network_mode             = "awsvpc"
  volume {
    name = local.data_volume_name
    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.prometheus.id
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2999
      authorization_config {
        access_point_id = aws_efs_access_point.prometheus.id
        iam             = "ENABLED"
      }
    }
  }

  volume {
    name = "task"
  }

  execution_role_arn = aws_iam_role.prometheus_execution.arn
  task_role_arn      = aws_iam_role.concourse_prometheus.arn
}

resource "aws_ecs_service" "prometheus" {
  name                               = "${var.deployment}-prometheus"
  cluster                            = aws_ecs_cluster.concourse_grafana.name
  task_definition                    = aws_ecs_task_definition.prometheus.arn
  desired_count                      = 1
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
  launch_type                        = "FARGATE"
  platform_version                   = "1.4.0"

  load_balancer {
    target_group_arn = aws_lb_target_group.concourse_prometheus_ecs.arn
    container_name   = "prometheus"
    container_port   = "9090"
  }

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.prometheus_security_group_id]
  }

  service_registries {
    registry_arn   = aws_service_discovery_service.prometheus.arn
    container_name = "prometheus"
  }
}

resource "aws_service_discovery_service" "prometheus" {
  name = "${var.deployment}-prometheus"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.monitoring_apps.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
