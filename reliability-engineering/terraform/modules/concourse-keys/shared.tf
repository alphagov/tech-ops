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

output "concourse_worker_shared_kms_key_id" {
  value = "${aws_kms_key.concourse_worker_shared.id}"
}

output "concourse_worker_shared_kms_key_arn" {
  value = "${aws_kms_key.concourse_worker_shared.arn}"
}
