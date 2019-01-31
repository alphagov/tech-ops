resource "aws_ssm_parameter" "concourse_web_ssh_key" {
  name        = "/${var.deployment}/concourse/web/ssh_key"
  type        = "SecureString"
  description = "Concourse web ssh private key"
  value       = "${var.web_ssh_private_key_pem}"
  key_id      = "${var.web_kms_key_id}"

  tags = {
    Deployment = "${var.deployment}"
  }
}

resource "aws_ssm_parameter" "concourse_web_session_key" {
  name        = "/${var.deployment}/concourse/web/session_key"
  type        = "SecureString"
  description = "Concourse web session key"
  value       = "${var.web_session_private_key_pem}"
  key_id      = "${var.web_kms_key_id}"

  tags = {
    Deployment = "${var.deployment}"
  }
}

resource "aws_ssm_parameter" "concourse_web_db_password" {
  name        = "/${var.deployment}/concourse/web/db_password"
  type        = "SecureString"
  description = "Password to Concourse Postgres Database"
  value       = "${random_string.concourse_db_password.result}"
  key_id      = "${var.web_kms_key_id}"

  tags = {
    Deployment = "${var.deployment}"
  }
}

resource "aws_s3_bucket_object" "concourse_web_authorized_worker_keys" {
  bucket  = "${aws_s3_bucket.concourse_web.bucket}"
  key     = "authorized_worker_keys"
  content = "${join("\n", values(var.worker_ssh_public_keys_openssh))}"
  etag    = "${md5(join("\n", values(var.worker_ssh_public_keys_openssh)))}"
}

resource "aws_s3_bucket_object" "concourse_web_team_authorized_worker_keys" {
  bucket  = "${aws_s3_bucket.concourse_web.bucket}"
  key     = "team_authorized_worker_keys.json"
  content = "${jsonencode(var.worker_ssh_public_keys_openssh)}"
  etag    = "${md5(jsonencode(var.worker_ssh_public_keys_openssh))}"
}
