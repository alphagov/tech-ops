resource "tls_private_key" "web_page_test_controller" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "web_page_test_controller" {
  key_name   = "${var.env}-controller"
  public_key = "${tls_private_key.web_page_test_controller.public_key_openssh}"
}
