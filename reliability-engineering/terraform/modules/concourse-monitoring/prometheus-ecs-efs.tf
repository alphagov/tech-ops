resource "aws_efs_file_system" "prometheus" {
  creation_token = "${var.deployment}-prometheus"

  tags = {
    Name = "prometheus"
  }
}

resource "aws_efs_access_point" "prometheus" {
  file_system_id = aws_efs_file_system.prometheus.id
  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/opt/data"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "0755"
    }
  }
}

resource "aws_efs_file_system_policy" "prometheus_data_volume_access" {
  file_system_id = aws_efs_file_system.prometheus.id
  policy         = data.aws_iam_policy_document.prometheus_data_volume_access.json
}

resource "aws_efs_mount_target" "prometheus" {
  count           = length(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.prometheus.id
  subnet_id       = element(var.private_subnet_ids, count.index)
  security_groups = [aws_security_group.efs_mount.id]
}
