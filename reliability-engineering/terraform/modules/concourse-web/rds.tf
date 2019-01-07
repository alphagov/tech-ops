resource "random_string" "concourse_db_password" {
  length  = 64
  special = false
}

resource "aws_db_subnet_group" "concourse" {
  name       = "${var.deployment}-concourse"
  subnet_ids = ["${var.private_subnet_ids}"]

  tags {
    Name       = "${var.deployment}-concourse"
    Deployment = "${var.deployment}"
  }
}

resource "aws_db_instance" "concourse" {
  identifier                = "${var.deployment}-concourse"
  name                      = "concourse"
  username                  = "concourse"
  password                  = "${random_string.concourse_db_password.result}"
  db_subnet_group_name      = "${aws_db_subnet_group.concourse.name}"
  allocated_storage         = "${var.db_storage_gb}"
  storage_type              = "gp2"
  engine                    = "postgres"
  instance_class            = "${var.db_instance_type}"
  final_snapshot_identifier = "${var.deployment}-concourse-final"
  storage_encrypted         = true
  vpc_security_group_ids    = ["${aws_security_group.concourse_db.id}"]

  tags {
    Name       = "${var.deployment}-concourse"
    Deployment = "${var.deployment}"
  }
}
