# resource "aws_iam_openid_connect_provider" "concourse_secrets_admin" {
#   for_each = (
#     trimspace(var.openid_connect_provider_url) != "" ||
#     trimspace(var.openid_connect_provider_client_id) != "" ||
#     length(var.openid_connect_provider_tls_cert_thumbprints) != 0
#   ) ? toset(["main"]) : toset([])

#   url = var.openid_connect_provider_url

#   client_id_list = [
#     var.openid_connect_provider_client_id,
#   ]

#   thumbprint_list = var.openid_connect_provider_tls_cert_thumbprints
# }

# output "aws_iam_openid_connect_provider_arn" {
#   value = contains(keys(aws_iam_openid_connect_provider.concourse_secrets_admin), "main") ? aws_iam_openid_connect_provider.concourse_secrets_admin["main"].arn : ""
# }
