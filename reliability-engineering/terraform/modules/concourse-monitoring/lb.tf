resource "aws_lb" "concourse_monitoring" {
  name               = "${var.deployment}-concourse-monitoring"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.concourse_monitoring_lb.id]
  subnets            = var.public_subnet_ids

  tags = {
    Name       = "${var.deployment}-concourse-monitoring"
    Deployment = var.deployment
  }
}

resource "aws_lb_listener" "concourse_monitoring_https" {
  load_balancer_arn = aws_lb.concourse_monitoring.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = aws_acm_certificate_validation.concourse_web.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "📈"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener" "concourse_monitoring_http" {
  load_balancer_arn = aws_lb.concourse_monitoring.arn
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

resource "aws_lb_target_group" "concourse_prometheus_ecs" {
  name        = "${var.deployment}-prometheus-ecs"
  port        = 9090
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path = "/api/v1/status/config"
  }
}

resource "aws_lb_listener_rule" "concourse_prometheus_ecs" {
  listener_arn = aws_lb_listener.concourse_monitoring_https.arn
  priority     = 99

  action {
    type = "forward"

    target_group_arn = aws_lb_target_group.concourse_prometheus_ecs.arn
  }

  condition {
    host_header {
      values = ["prom.*"]
    }
  }
}

resource "aws_lb_target_group" "concourse_prometheus" {
  count = 2

  name     = "${var.deployment}-concourse-prometheus"
  port     = 9090
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path = "/api/v1/status/config"
  }
}

resource "aws_lb_listener_rule" "concourse_prometheus" {
  count = 2

  listener_arn = aws_lb_listener.concourse_monitoring_https.arn
  priority     = 100 + count.index

  action {
    type = "forward"

    target_group_arn = aws_lb_target_group.concourse_prometheus[count.index].arn
  }

  condition {
    host_header {
      values = ["prom-${count.index + 1}.*"]
    }
  }
}

resource "aws_lb_target_group" "concourse_grafana" {
  name        = "${var.deployment}-concourse-grafana"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 5
    timeout             = 3
    matcher             = "200"
    path                = "/api/health"
  }
}

resource "aws_lb_listener_rule" "concourse_grafana" {
  listener_arn = aws_lb_listener.concourse_monitoring_https.arn
  priority     = 110

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.concourse_grafana.arn
  }

  condition {
    host_header {
      values = ["grafana.*"]
    }
  }
}
