output "role_id" {
  value = "${aws_iam_role.gds_security_audit_role.id}"
}

output "role_arn" {
  value = "${aws_iam_role.gds_security_audit_role.arn}"
}

output "role_name" {
  value = "${aws_iam_role.gds_security_audit_role.name}"
}
