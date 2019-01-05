resource "aws_ecs_cluster" "concourse_grafana" {
  name = "${var.deployment}-grafana"
}
