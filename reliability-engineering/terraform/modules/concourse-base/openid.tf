resource "aws_iam_openid_connect_provider" "concourse_secrets_admin" {
  url = var.openid_connect_provider_url

  client_id_list = [
    var.openid_connect_provider_client_id,
  ]

  thumbprint_list = var.openid_connect_provider_tls_cert_thumbprints
}

output "aws_iam_openid_connect_provider_arn" {
  value = aws_iam_openid_connect_provider.concourse_secrets_admin.arn
}
