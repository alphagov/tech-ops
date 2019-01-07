resource "aws_kms_key" "concourse_grafana" {
  description = "${var.deployment} concourse grafana"
}

resource "aws_kms_alias" "concourse_grafana" {
  name          = "alias/${var.deployment}-concourse-grafana"
  target_key_id = "${aws_kms_key.concourse_grafana.key_id}"
}

data "template_file" "concourse_grafana_cloud_init" {
  template = "${file("${path.module}/files/grafana-init.sh")}"

  vars {
    deployment       = "${var.deployment}"
    vpc_dns_resolver = "${local.vpc_dns_resolver}"
  }
}

resource "aws_launch_template" "concourse_grafana" {
  name_prefix            = "${var.deployment}-concourse-grafana-"
  ebs_optimized          = true
  image_id               = "${data.aws_ami.ubuntu_bionic.id}"
  instance_type          = "${var.grafana_instance_type}"
  vpc_security_group_ids = ["${aws_security_group.concourse_grafana.id}"]

  user_data = "${
    base64encode(data.template_file.concourse_grafana_cloud_init.rendered)
  }"

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 20
    }
  }

  iam_instance_profile {
    name = "${aws_iam_instance_profile.concourse_grafana.name}"
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name       = "${var.deployment}-concourse-grafana"
      Deployment = "${var.deployment}"
      Role       = "grafana"
    }
  }

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name       = "${var.deployment}-concourse-grafana"
      Deployment = "${var.deployment}"
    }
  }

  tags {
    Deployment = "${var.deployment}"
  }
}

resource "aws_autoscaling_group" "concourse_grafana" {
  name = "${join("-", list(
    "${aws_launch_template.concourse_grafana.id}",
    "${aws_launch_template.concourse_grafana.latest_version}"
  ))}"

  max_size            = 2
  min_size            = 0
  desired_capacity    = 1
  vpc_zone_identifier = ["${var.private_subnet_ids}"]

  launch_template = {
    id      = "${aws_launch_template.concourse_grafana.id}"
    version = "$$Latest"
  }

  tag {
    key                 = "Deployment"
    value               = "${var.deployment}"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_string" "concourse_grafana_db_password" {
  length  = 64
  special = false
}

resource "aws_ssm_parameter" "concourse_grafana_db_password" {
  name   = "/${var.deployment}/grafana/db-password"
  type   = "SecureString"
  key_id = "${aws_kms_key.concourse_grafana.key_id}"
  value  = "${random_string.concourse_grafana_db_password.result}"
}

resource "random_string" "concourse_grafana_admin_password" {
  length  = 32
  special = false
}

resource "aws_ssm_parameter" "concourse_grafana_admin_password" {
  name   = "/${var.deployment}/grafana/grafana-admin-password"
  type   = "SecureString"
  key_id = "${aws_kms_key.concourse_grafana.key_id}"
  value  = "${random_string.concourse_grafana_admin_password.result}"
}

resource "aws_db_subnet_group" "concourse_grafana_db" {
  name       = "${var.deployment}-concourse-grafana-db"
  subnet_ids = ["${var.private_subnet_ids}"]
}

resource "aws_db_instance" "concourse_grafana_db" {
  identifier                = "${var.deployment}-concourse-grafana"
  allocated_storage         = 25
  storage_type              = "gp2"
  engine                    = "postgres"
  instance_class            = "db.t2.small"
  name                      = "grafana"
  username                  = "grafana"
  password                  = "${random_string.concourse_grafana_db_password.result}"
  vpc_security_group_ids    = ["${aws_security_group.concourse_grafana_db.id}"]
  db_subnet_group_name      = "${aws_db_subnet_group.concourse_grafana_db.name}"
  final_snapshot_identifier = "${var.deployment}-concourse-grafana-final"
  backup_retention_period   = 7
  storage_encrypted         = true
}

data "template_file" "concourse_grafana_container_def" {
  template = "${file("${path.module}/files/grafana-container-def.json")}"

  vars {
    deployment      = "${var.deployment}"
    grafana_url     = "${local.grafana_url}"
    database_host   = "${aws_db_instance.concourse_grafana_db.endpoint}"
    aws_account_id  = "${data.aws_caller_identity.account.account_id}"
    github_team_ids = "${join(",", var.grafana_allowed_github_team_ids)}"
  }
}

resource "aws_ecs_task_definition" "concourse_grafana_task_def" {
  family                = "${var.deployment}-concourse-grafana"
  container_definitions = "${data.template_file.concourse_grafana_container_def.rendered}"
  execution_role_arn    = "${aws_iam_role.concourse_grafana_execution.arn}"
}

resource "aws_ecs_service" "concourse_grafana" {
  name            = "${var.deployment}-concourse-grafana"
  cluster         = "${aws_ecs_cluster.concourse_grafana.name}"
  task_definition = "${aws_ecs_task_definition.concourse_grafana_task_def.arn}"

  desired_count                      = 1
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  load_balancer {
    target_group_arn = "${aws_lb_target_group.concourse_grafana.id}"
    container_name   = "grafana"
    container_port   = "3000"
  }
}
