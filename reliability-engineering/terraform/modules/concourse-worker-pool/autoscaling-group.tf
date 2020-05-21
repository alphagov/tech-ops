resource "aws_autoscaling_group" "concourse_worker" {
  name                = "${var.deployment}-${var.name}-concourse-worker"
  max_size            = var.desired_capacity * 2
  min_size            = 0
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.subnet_ids

  termination_policies = [
    "OldestLaunchConfiguration",
    "OldestInstance",
  ]

  launch_template {
    id      = aws_launch_template.concourse_worker.id
    version = "$Latest"
  }

  tag {
    key                 = "Deployment"
    value               = var.deployment
    propagate_at_launch = true
  }
}
