resource "random_string" "local_user_password" {
  count = "${length(var.worker_team_names)}"

  length  = 32
}

output "local_user_passwords" {
  value = "${
    zipmap(
      var.worker_team_names,
      random_string.local_user_password
    )
  }"
}
