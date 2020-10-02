data "aws_route53_zone" "private_root" {
  zone_id = var.private_root_zone_id
}

locals {
  concourse_url = replace(
    "web.${data.aws_route53_zone.private_root.name}",
    "/[.]$/",
    "",
  )
}
