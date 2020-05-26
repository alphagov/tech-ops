data "aws_ami" "ubuntu_bionic" {
  most_recent = true

  # canonical
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

data "template_file" "concourse_worker_cloud_init" {
  template = file("${path.module}/files/worker-init.sh")

  vars = {
    deployment        = var.deployment
    worker_team_name  = var.name
    concourse_host    = local.concourse_url
    concourse_version = var.concourse_version
    concourse_sha1    = var.concourse_sha1
  }
}

resource "aws_launch_template" "concourse_worker" {
  name_prefix            = "${var.deployment}-${var.name}-concourse-worker-"
  ebs_optimized          = true
  image_id               = data.aws_ami.ubuntu_bionic.id
  instance_type          = var.instance_type
  vpc_security_group_ids = var.security_group_ids

  user_data = base64encode(data.template_file.concourse_worker_cloud_init.rendered)

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = var.volume_size
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.concourse_worker.name
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name       = "${var.deployment}-${var.name}-concourse-worker"
      Deployment = var.deployment
      Role       = "concourse-worker"
      Team       = var.name
    }
  }

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name       = "${var.deployment}-${var.name}-concourse-worker"
      Deployment = var.deployment
    }
  }

  tags = {
    Deployment = var.deployment
  }
}
