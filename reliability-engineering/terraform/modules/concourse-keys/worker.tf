resource "tls_private_key" "concourse_worker_ssh_keys" {
  for_each = toset(var.worker_team_names)

  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  concourse_worker_ssh_public_keys_openssh = zipmap(
    var.worker_team_names,
    [for key in tls_private_key.concourse_worker_ssh_keys : key.public_key_openssh],
  )

  concourse_worker_ssh_private_keys_pem = zipmap(
    var.worker_team_names,
    [for key in tls_private_key.concourse_worker_ssh_keys : key.private_key_pem],
  )
}

output "concourse_worker_ssh_public_keys_openssh" {
  value = local.concourse_worker_ssh_public_keys_openssh
}

output "concourse_worker_ssh_private_keys_pem" {
  value = local.concourse_worker_ssh_private_keys_pem
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
  value = zipmap(var.worker_team_names, [for role in aws_iam_role.concourse_workers : role.name])
}

output "concourse_worker_iam_role_arns" {
  value = zipmap(var.worker_team_names, [for role in aws_iam_role.concourse_workers : role.arn])
}
