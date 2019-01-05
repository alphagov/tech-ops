variable "source_sg_id" {
  type = "string"
}

variable "destination_sg_id" {
  type = "string"
}

variable "from_port" {
  type = "string"
}

variable "to_port" {
  type = "string"
}

resource "aws_security_group_rule" "ingress" {
  type     = "ingress"
  protocol = "tcp"

  from_port = "${var.from_port}"
  to_port   = "${var.to_port}"

  source_security_group_id = "${var.source_sg_id}"
  security_group_id        = "${var.destination_sg_id}"
}

resource "aws_security_group_rule" "egress" {
  type     = "egress"
  protocol = "tcp"

  from_port = "${var.from_port}"
  to_port   = "${var.to_port}"

  # source is destination for egress
  source_security_group_id = "${var.destination_sg_id}"
  security_group_id        = "${var.source_sg_id}"
}
