resource "random_string" "local_user_password" {
  count = length(var.worker_team_names)

  special = false
  length  = 32
}

resource "aws_ssm_parameter" "concourse_local_usernames_and_passwords" {
  count = length(var.worker_team_names)

  name        = "/${var.deployment}/concourse/pipelines/${element(var.worker_team_names, count.index)}/readonly_local_user_password"
  type        = "SecureString"
  description = "Password for the local user with admin access to team ${element(var.worker_team_names, count.index)}"
  value       = random_string.local_user_password[count.index].result
  key_id      = aws_kms_key.concourse_worker_shared.key_id

  tags = {
    Deployment = var.deployment
  }
}

output "local_user_passwords" {
  value = zipmap(
    var.worker_team_names,
    random_string.local_user_password.*.result,
  )
}
