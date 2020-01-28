resource "aws_elb" "concourse_web" {
  name                        = "${var.deployment}-concourse-web"
  cross_zone_load_balancing   = true
  connection_draining         = true
  connection_draining_timeout = 60
  idle_timeout                = 60
  internal                    = true
  subnets                     = var.private_subnet_ids
  security_groups             = [aws_security_group.concourse_elb.id]

  listener {
    instance_port     = 2222
    instance_protocol = "tcp"
    lb_port           = 2222
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8080/"
    interval            = 10
  }

  tags = {
    Name       = "${var.deployment}-concourse-web"
    Deployment = var.deployment
  }
}
