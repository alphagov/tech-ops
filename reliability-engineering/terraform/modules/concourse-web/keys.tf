resource "aws_kms_key" "concourse_web" {
  description = "${var.deployment} concourse web"
}

resource "aws_kms_alias" "concourse_web" {
  name          = "alias/${var.deployment}-concourse-web"
  target_key_id = "${aws_kms_key.concourse_web.key_id}"
}

locals {
  kms_principal_template = "arn:aws:iam::${data.aws_caller_identity.account.account_id}"

  kms_root_principal = "${local.kms_principal_template}:root"

  kms_worker_principals = "${formatlist(
    "${local.kms_principal_template}:role/${var.deployment}-%s-concourse-worker",
    var.worker_team_names
  )}"

  kms_principals = "${concat(
    list(
      local.kms_root_principal,
      aws_iam_role.concourse_web.arn,
    ),
    local.kms_worker_principals
  )}"
}

resource "aws_kms_key" "concourse_worker_shared" {
  description = "${var.deployment} concourse worker shared"

  policy = <<-POLICY
  {
    "Version": "2012-10-17",
    "Id": "key-default-1",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": ${jsonencode(local.kms_principals)}
        },
        "Action": "kms:*",
        "Resource": "*"
      }
    ]
  }
  POLICY
}

resource "aws_kms_alias" "concourse_worker_shared" {
  name          = "alias/${var.deployment}-concourse-worker-shared"
  target_key_id = "${aws_kms_key.concourse_worker_shared.key_id}"
}

output "concourse_worker_shared_kms_key_arn" {
  value = "${aws_kms_key.concourse_worker_shared.arn}"
}

resource "tls_private_key" "concourse_worker_ssh_keys" {
  count = "${length(var.worker_team_names)}"

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_private_key" "concourse_web_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_private_key" "concourse_web_session_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  concourse_worker_openssh_public_keys = "${join(
    "\n",
    tls_private_key.concourse_worker_ssh_keys.*.public_key_openssh
  )}"
}

resource "aws_ssm_parameter" "concourse_worker_ssh_private_keys" {
  count = "${length(var.worker_team_names)}"

  name = "/${var.deployment}/concourse/worker/${
    element(var.worker_team_names, count.index)
  }/ssh_key"

  type        = "SecureString"
  description = "Concourse worker ssh private key"
  key_id      = "${aws_kms_key.concourse_worker_shared.id}"

  value = "${element(
    tls_private_key.concourse_worker_ssh_keys.*.private_key_pem,
    count.index
  )}"

  lifecycle {
    ignore_changes = ["value"]
  }

  tags = {
    Deployment = "${var.deployment}"
  }
}

resource "aws_ssm_parameter" "concourse_worker_web_ssh_public_key" {
  count = "${length(var.worker_team_names)}"

  name = "/${var.deployment}/concourse/worker/${
    element(var.worker_team_names, count.index)
  }/web_ssh_public_key"

  type        = "SecureString"
  description = "Concourse worker ssh private key"
  key_id      = "${aws_kms_key.concourse_worker_shared.id}"
  value       = "${tls_private_key.concourse_web_ssh_key.public_key_openssh}"

  tags = {
    Deployment = "${var.deployment}"
  }
}

resource "aws_ssm_parameter" "concourse_web_ssh_key" {
  name        = "/${var.deployment}/concourse/web/ssh_key"
  type        = "SecureString"
  description = "Concourse web ssh private key"
  value       = "${tls_private_key.concourse_web_ssh_key.private_key_pem}"
  key_id      = "${aws_kms_key.concourse_web.id}"

  tags = {
    Deployment = "${var.deployment}"
  }
}

resource "aws_ssm_parameter" "concourse_web_session_key" {
  name        = "/${var.deployment}/concourse/web/session_key"
  type        = "SecureString"
  description = "Concourse web session key"
  value       = "${tls_private_key.concourse_web_session_key.private_key_pem}"
  key_id      = "${aws_kms_key.concourse_web.id}"

  tags = {
    Deployment = "${var.deployment}"
  }
}

resource "aws_ssm_parameter" "concourse_web_authorized_worker_keys" {
  name        = "/${var.deployment}/concourse/web/authorised_worker_keys"
  type        = "SecureString"
  description = "Authorised worker public keys in OpenSSH format"
  value       = "${local.concourse_worker_openssh_public_keys}"
  key_id      = "${aws_kms_key.concourse_web.id}"

  tags = {
    Deployment = "${var.deployment}"
  }
}

resource "aws_ssm_parameter" "concourse_web_db_password" {
  name        = "/${var.deployment}/concourse/web/db_password"
  type        = "SecureString"
  description = "Password to Concourse Postgres Database"
  value       = "${random_string.concourse_db_password.result}"
  key_id      = "${aws_kms_key.concourse_web.id}"

  tags = {
    Deployment = "${var.deployment}"
  }
}
