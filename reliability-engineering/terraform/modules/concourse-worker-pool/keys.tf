resource "aws_ssm_parameter" "concourse_worker_ssh_private_key" {
  name        = "/${var.deployment}/concourse/worker/${var.name}/ssh_key"
  type        = "SecureString"
  description = "Concourse worker ssh private key"
  key_id      = var.kms_key_id
  value       = var.worker_ssh_private_key_pem

  tags = {
    Deployment = var.deployment
  }
}

resource "aws_ssm_parameter" "concourse_worker_web_ssh_public_key" {
  name = "/${var.deployment}/concourse/worker/${var.name}/web_ssh_public_key"

  type        = "SecureString"
  description = "Concourse worker ssh public key"
  key_id      = var.kms_key_id
  value       = var.web_ssh_public_key_openssh

  tags = {
    Deployment = var.deployment
  }
}
