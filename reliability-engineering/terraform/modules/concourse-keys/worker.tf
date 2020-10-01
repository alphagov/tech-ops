resource "tls_private_key" "concourse_worker_ssh_keys" {
  count = length(var.worker_team_names)

  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  concourse_worker_ssh_public_keys_openssh = zipmap(
    var.worker_team_names,
    tls_private_key.concourse_worker_ssh_keys.*.public_key_openssh,
  )

  concourse_worker_ssh_private_keys_pem = zipmap(
    var.worker_team_names,
    tls_private_key.concourse_worker_ssh_keys.*.private_key_pem,
  )
}

output "concourse_worker_ssh_public_keys_openssh" {
  value = local.concourse_worker_ssh_public_keys_openssh
}

output "concourse_worker_ssh_private_keys_pem" {
  value = local.concourse_worker_ssh_private_keys_pem
}

resource "aws_iam_role" "concourse_workers" {
  count = length(var.worker_team_names)

  name = "${var.deployment}-${var.worker_team_names[count.index]}-concourse-worker"

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
  value = zipmap(var.worker_team_names, aws_iam_role.concourse_workers.*.name)
}

output "concourse_worker_iam_role_arns" {
  value = zipmap(var.worker_team_names, aws_iam_role.concourse_workers.*.arn)
}

resource "tls_private_key" "concourse_global_worker_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

output "concourse_global_worker_ssh_public_key_openssh" {
  value = tls_private_key.concourse_global_worker_ssh_key.public_key_openssh
}

output "concourse_global_worker_ssh_private_key_pem" {
  value = tls_private_key.concourse_global_worker_ssh_key.private_key_pem
}

resource "aws_iam_role" "concourse_global_worker" {
  name = "${var.deployment}-global-concourse-worker"

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
      }
    ]
  }
ARP
}

output "concourse_global_worker_iam_role_name" {
  value = aws_iam_role.concourse_global_worker.name
}
