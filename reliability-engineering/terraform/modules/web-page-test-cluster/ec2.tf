# EC2
#
# We can only be in Ireland because there are a limited number of AMIs
# US and Ireland mainly
#
# LB -> Controller VM <-> Agent VM
#
# Everything has ingress/egress everywhere, but in practice the VMs are not
# routable to the internet, so we don't care

locals {
  # eu-west-1 AMI ID for Web Page Test (linux)
  ami_id = "ami-9978f6ee"
}

resource "aws_security_group" "web_page_test_controller" {
  name        = "${var.env}-controller"
  description = "ingress/egress/all"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["${var.ingress_cidrs}"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["${aws_vpc.main.cidr_block}"]
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = -1
    security_groups = ["${aws_security_group.web_page_test_controller_lb.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web_page_test_agent" {
  name        = "${var.env}-agent"
  description = "ingress/egress/all"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web_page_test_controller_lb" {
  name        = "${var.env}-controller-lb"
  description = "ingress/egress/all"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["${var.ingress_cidrs}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ssm_parameter" "web_page_test_google_oauth_client_secret" {
  name = "/web-page-test/google-oauth-client-secret"
}

resource "random_string" "api_key" {
  length  = 20
  number  = false
  special = false
  upper   = false
}

resource "aws_instance" "web_page_test_controller" {
  ami           = "${local.ami_id}"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.public.0.id}"
  private_ip    = "10.0.1.100"                                        # Arbitrarily selected
  key_name      = "${aws_key_pair.web_page_test_controller.key_name}"

  associate_public_ip_address = true

  vpc_security_group_ids = [
    "${aws_security_group.web_page_test_controller.id}",
  ]

  user_data = <<-EOF
  ec2_key=${aws_iam_access_key.web_page_test_controller.id}
  ec2_secret=${aws_iam_access_key.web_page_test_controller.secret}
  ec2_use_server_private_ip=1

  archive_s3_server=s3.amazonaws.com
  archive_s3_key=${aws_iam_access_key.web_page_test_controller.id}
  archive_s3_secret=${aws_iam_access_key.web_page_test_controller.secret}
  archive_s3_bucket=${var.bucket_name}

  google_oauth_client_id=${trimspace(var.google_oauth_client_id)}
  google_oauth_client_secret=${trimspace(var.google_oauth_client_secret)}

  api_key=${random_string.api_key.result}
  headless=0
  iq=80
  pngss=1

  host=localhost

  EC2.default=eu-west-1
  EC2.eu-west-1.min=1
  EC2.eu-west-1.max=3
  EC2.eu-west-1.subnetId=${aws_subnet.private.id}
  EC2.eu-west-1.securityGroup=${aws_security_group.web_page_test_agent.id}
  EOF

  tags = {
    Name = "WebPagetest Controller"
  }
}

resource "aws_lb" "web_page_test_controller" {
  name               = "web-page-test-controller"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.web_page_test_controller_lb.id}"]
  subnets            = ["${aws_subnet.public.*.id}"]
}

resource "aws_lb_target_group" "web_page_test_controller" {
  name     = "web-page-test-controller"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.main.id}"
}

resource "aws_lb_target_group_attachment" "web_page_test_controller" {
  target_group_arn = "${aws_lb_target_group.web_page_test_controller.arn}"
  target_id        = "${aws_instance.web_page_test_controller.id}"
  port             = 80
}

resource "aws_lb_listener" "web_page_test_controller" {
  load_balancer_arn = "${aws_lb.web_page_test_controller.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${aws_acm_certificate.domain.arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.web_page_test_controller.arn}"
  }
}

resource "aws_route53_record" "web_page_test" {
  name    = "${var.subdomain}.${var.domain}"
  type    = "A"
  zone_id = "${data.aws_route53_zone.zone.id}"

  alias {
    name                   = "${aws_lb.web_page_test_controller.dns_name}"
    zone_id                = "${aws_lb.web_page_test_controller.zone_id}"
    evaluate_target_health = false
  }
}

resource "null_resource" "web_page_test_controller_provisioning" {
  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = "${aws_instance.web_page_test_controller.public_ip}"
    private_key = "${tls_private_key.web_page_test_controller.private_key_pem}"
  }

  triggers = {
    locations_ini_content = "${sha1(file("${path.module}/files/ec2_locations.ini"))}"
    instance_id = "${aws_instance.web_page_test_controller.id}"
  }

  provisioner "file" {
    source      = "${path.module}/files/ec2_locations.ini"
    destination = "/tmp/ec2_locations.ini"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/ec2_locations.ini /var/www/webpagetest/www/settings/ec2_locations.ini",
      "sudo chown www-data:www-data /var/www/webpagetest/www/settings/ec2_locations.ini",
    ]
  }
}
