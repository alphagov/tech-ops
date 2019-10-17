output "static_egress_ip" {
  value = "${aws_eip.nat.public_ip}"
}
