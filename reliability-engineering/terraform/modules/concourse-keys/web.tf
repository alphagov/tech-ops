resource "aws_iam_role" "concourse_web" {
  name = "${var.deployment}-concourse-web"

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

output "concourse_web_iam_role_name" {
  value = "${aws_iam_role.concourse_web.name}"
}

resource "aws_kms_key" "concourse_web" {
  description = "${var.deployment} concourse web"
}

output "concourse_web_kms_key_id" {
  value = "${aws_kms_key.concourse_web.id}"
}

output "concourse_web_kms_key_arn" {
  value = "${aws_kms_key.concourse_web.arn}"
}

resource "aws_kms_alias" "concourse_web" {
  name          = "alias/${var.deployment}-concourse-web"
  target_key_id = "${aws_kms_key.concourse_web.key_id}"
}

resource "tls_private_key" "concourse_web_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

output "concourse_web_ssh_public_key_openssh" {
  value = "${tls_private_key.concourse_web_ssh_key.public_key_openssh}"
}

output "concourse_web_ssh_private_key_pem" {
  value = "${tls_private_key.concourse_web_ssh_key.private_key_pem}"
}

resource "tls_private_key" "concourse_web_session_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

output "concourse_web_session_private_key_pem" {
  value = "${tls_private_key.concourse_web_session_key.private_key_pem}"
}
