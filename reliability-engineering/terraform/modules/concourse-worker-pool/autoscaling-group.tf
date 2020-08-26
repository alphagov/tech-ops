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

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.concourse_worker.id
        version            = "$Latest"
      }

      dynamic "override" {
        for_each = coalescelist(var.spot_instance_types, [var.instance_type])
        content {
          instance_type = override.value
        }
      }
    }

    instances_distribution {
      on_demand_percentage_above_base_capacity = var.on_demand_percentage
    }
  }

  tag {
    key                 = "Deployment"
    value               = var.deployment
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_schedule" "reduce_for_the_weekend" {
  scheduled_action_name = "reduce-for-the-weekend"
  min_size = -1
  max_size = -1
  # don't add an instance if desired_capacity == 0
  desired_capacity = min(1, var.desired_capacity)
  recurrence = "0 20 * * 5" # 20:00 every Friday
  autoscaling_group_name = aws_autoscaling_group.concourse_worker.name
}

resource "aws_autoscaling_schedule" "increase_for_the_work_week" {
  scheduled_action_name = "increase-for-the-work-week"
  min_size = -1
  max_size = -1
  desired_capacity = var.desired_capacity
  recurrence = "0 7 * * 1" # 07:00 every Monday
  autoscaling_group_name = aws_autoscaling_group.concourse_worker.name
}
