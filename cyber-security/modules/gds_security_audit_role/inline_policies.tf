data "aws_iam_policy_document" "support_inline_policy_document" {
  statement {
    effect    = "Allow"
    actions   = ["support:*"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "support_inline_policy" {
  name    = "${var.prefix}GDSSecurityAuditInlineSupportPolicy"
  role    = "${aws_iam_role.gds_security_audit_role.id}"
  policy  = "${data.aws_iam_policy_document.support_inline_policy_document.json}"
}

data "aws_iam_policy_document" "sts_inline_policy_document" {
  statement {
    effect    = "Allow"
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "sts_inline_policy" {
  name    = "${var.prefix}GDSSecurityAuditInlineSTSPolicy"
  role    = "${aws_iam_role.gds_security_audit_role.id}"
  policy  = "${data.aws_iam_policy_document.sts_inline_policy_document.json}"
}
