resource "tls_private_key" "concourse_worker_ssh_keys" {
  for_each = toset(var.worker_team_names)

  algorithm = "RSA"
  rsa_bits  = 4096
}

output "concourse_worker_ssh_public_keys_openssh" {
  value = {
    for name in var.worker_team_names : name => tls_private_key.concourse_worker_ssh_keys[name].public_key_openssh
  }
}

output "concourse_worker_ssh_private_keys_pem" {
  value = {
    for name in var.worker_team_names : name => tls_private_key.concourse_worker_ssh_keys[name].private_key_pem
  }
}

resource "aws_iam_role" "concourse_workers" {
  for_each = toset(var.worker_team_names)

  name = "${var.deployment}-${each.key}-concourse-worker"

  assume_role_policy = <<-ARP
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow"
      }, {
        "Action": "sts:AssumeRole",
        "Principal": {
          "AWS": "${aws_iam_role.concourse_sts_rotation_lambda_execution.arn}"
        },
        "Effect": "Allow"
      }
    ]
  }
ARP
}

output "concourse_worker_iam_role_names" {
  value = {
    for name in var.worker_team_names : name => aws_iam_role.concourse_workers[name].name
  }
}

output "concourse_worker_iam_role_arns" {
  value = {
    for name in var.worker_team_names : name => aws_iam_role.concourse_workers[name].arn
  }
}
