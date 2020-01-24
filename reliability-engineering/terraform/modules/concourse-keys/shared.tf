locals {
  kms_principals = concat(
    [
      "arn:aws:iam::${data.aws_caller_identity.account.account_id}:root",
      aws_iam_role.concourse_web.arn,
    ],
    aws_iam_role.concourse_workers.*.arn,
  )
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
  target_key_id = aws_kms_key.concourse_worker_shared.key_id
}

output "concourse_worker_shared_kms_key_id" {
  value = aws_kms_key.concourse_worker_shared.id
}

output "concourse_worker_shared_kms_key_arn" {
  value = aws_kms_key.concourse_worker_shared.arn
}
