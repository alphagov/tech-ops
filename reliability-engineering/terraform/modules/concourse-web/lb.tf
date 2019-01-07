resource "aws_lb" "concourse_web" {
  name               = "${var.deployment}-concourse-web"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.concourse_lb.id}"]
  subnets            = ["${var.public_subnet_ids}"]

  tags = {
    Name       = "${var.deployment}-concourse-web"
    Deployment = "${var.deployment}"
  }
}

resource "aws_lb_target_group" "concourse_web" {
  name     = "${var.deployment}-concourse-web"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"
}

resource "aws_lb_listener" "concourse_web_https" {
  load_balancer_arn = "${aws_lb.concourse_web.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = "${aws_acm_certificate_validation.concourse_public_deployment.certificate_arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.concourse_web.arn}"
  }
}

resource "aws_lb_listener" "concourse_web_http" {
  load_balancer_arn = "${aws_lb.concourse_web.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
