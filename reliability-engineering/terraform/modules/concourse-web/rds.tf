resource "random_string" "concourse_db_password" {
  length  = 64
  special = false
}

resource "aws_db_subnet_group" "concourse" {
  name       = "${var.deployment}-concourse"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name       = "${var.deployment}-concourse"
    Deployment = var.deployment
  }
}

resource "aws_db_instance" "concourse" {
  identifier                   = "${var.deployment}-concourse"
  name                         = "concourse"
  username                     = "concourse"
  password                     = random_string.concourse_db_password.result
  db_subnet_group_name         = aws_db_subnet_group.concourse.name
  allocated_storage            = var.db_storage_gb
  storage_type                 = var.db_storage_type
  iops                         = var.db_storage_iops
  engine                       = "postgres"
  engine_version               = "10"
  instance_class               = var.db_instance_type
  final_snapshot_identifier    = "${var.deployment}-concourse-final"
  storage_encrypted            = true
  vpc_security_group_ids       = [aws_security_group.concourse_db.id]
  ca_cert_identifier           = "rds-ca-2019"
  performance_insights_enabled = var.db_performance_insights_enabled
  deletion_protection          = true
  multi_az                     = var.db_multi_az
  backup_retention_period      = var.db_backup_retention_period

  tags = {
    Name       = "${var.deployment}-concourse"
    Deployment = var.deployment
  }
}
