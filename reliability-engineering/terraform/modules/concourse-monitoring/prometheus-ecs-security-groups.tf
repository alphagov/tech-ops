resource "aws_security_group" "efs_mount" {
  name   = "${var.deployment}-prometheus-efs-mount"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "efs_mount_outbound_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.efs_mount.id
}

resource "aws_security_group_rule" "efs_mount_inbound_from_prometheus" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = var.prometheus_security_group_id
  security_group_id        = aws_security_group.efs_mount.id
}

resource "aws_security_group_rule" "efs_mount_encrypted_inbound_from_prometheus" {
  type                     = "ingress"
  from_port                = 2999
  to_port                  = 2999
  protocol                 = "tcp"
  source_security_group_id = var.prometheus_security_group_id
  security_group_id        = aws_security_group.efs_mount.id
}
