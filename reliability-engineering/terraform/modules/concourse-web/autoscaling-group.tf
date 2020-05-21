resource "aws_autoscaling_group" "concourse_web" {
  name                = "${var.deployment}-concourse-web"
  max_size            = var.desired_capacity * 2
  min_size            = 0
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.concourse_web.arn]
  load_balancers      = [aws_elb.concourse_web.name]

  termination_policies = [
    "OldestLaunchConfiguration",
    "OldestInstance",
  ]

  launch_template {
    id      = aws_launch_template.concourse_web.id
    version = "$Latest"
  }

  tag {
    key                 = "Deployment"
    value               = var.deployment
    propagate_at_launch = true
  }
}
