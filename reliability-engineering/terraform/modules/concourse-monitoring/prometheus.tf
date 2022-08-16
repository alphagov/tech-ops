data "aws_ami" "ubuntu_focal" {
  most_recent = true

  # canonical
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

variable concourse_prometheus_cloud_init {
  default = {
    deployment       = var.deployment
    data_volume_size = var.prometheus_volume_size
  }
}

data "aws_subnet" "concourse_prometheus" {
  count = 2

  id = var.private_subnet_ids[count.index]
}

resource "aws_instance" "concourse_prometheus" {
  count = 2

  ami                    = data.aws_ami.ubuntu_focal.id
  instance_type          = var.prometheus_instance_type
  subnet_id              = var.private_subnet_ids[count.index]
  vpc_security_group_ids = [var.prometheus_security_group_id]

  iam_instance_profile = aws_iam_instance_profile.concourse_prometheus.name

  user_data = templatefile("${path.module}/files/prometheus-init.sh", var.concourse_prometheus_cloud_init)

  root_block_device {
    volume_size = 20
  }

  tags = {
    Name       = "${var.deployment}-concourse-prometheus"
    Deployment = var.deployment
    Role       = "prometheus"
  }
}

resource "aws_ebs_volume" "concourse_prometheus" {
  count = 2

  size      = var.prometheus_volume_size
  type      = "gp3"
  encrypted = true

  availability_zone = element(
    data.aws_subnet.concourse_prometheus.*.availability_zone,
    count.index,
  )

  tags = {
    Name       = "${var.deployment}-concourse-prometheus"
    Deployment = var.deployment
  }
}

resource "aws_volume_attachment" "concourse_prometheus_concourse_prometheus" {
  count = 2

  device_name = "/dev/xvdp"

  volume_id = aws_ebs_volume.concourse_prometheus[count.index].id

  instance_id = aws_instance.concourse_prometheus[count.index].id
}

resource "aws_lb_target_group_attachment" "concourse_prometheus" {
  count = 2
  port  = 9090

  target_group_arn = aws_lb_target_group.concourse_prometheus[count.index].arn

  target_id = aws_instance.concourse_prometheus[count.index].id
}
