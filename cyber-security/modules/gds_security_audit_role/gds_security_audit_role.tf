resource "aws_iam_role" "gds_security_audit_role" {
  name = "${var.prefix}GDSSecurityAudit"

  assume_role_policy = templatefile("${path.module}/json/trust.json", {
    prefix           = var.prefix
    chain_account_id = var.chain_account_id
  })
}

resource "aws_iam_role_policy_attachment" "gds_security_audit_role_policy_attachment" {
  role       = aws_iam_role.gds_security_audit_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

