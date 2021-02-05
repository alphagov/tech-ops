resource "random_string" "local_user_password" {
  for_each = toset(var.worker_team_names)

  special = false
  length  = 32
}

resource "aws_ssm_parameter" "concourse_local_usernames_and_passwords" {
  for_each = toset(var.worker_team_names)

  name        = "/${var.deployment}/concourse/pipelines/${each.key}/readonly_local_user_password"
  type        = "SecureString"
  description = "Password for the local user with admin access to team ${each.key}"
  value       = random_string.local_user_password[each.key].result
  key_id      = aws_kms_key.concourse_worker_shared.key_id

  tags = {
    Deployment = var.deployment
  }
}

output "local_user_passwords" {
  value = zipmap(
    var.worker_team_names,
    [for password in random_string.local_user_password : password.result],
  )
}
