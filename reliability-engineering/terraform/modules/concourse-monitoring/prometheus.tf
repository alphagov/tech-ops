data "aws_ami" "ubuntu_bionic" {
  most_recent = true

  # canonical
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

data "template_file" "concourse_prometheus_cloud_init" {
  template = "${file("${path.module}/files/prometheus-init.sh")}"

  vars {
    deployment = "${var.deployment}"
  }
}

data "aws_subnet" "concourse_prometheus" {
  id = "${element(var.private_subnet_ids, 0)}"
}

resource "aws_instance" "concourse_prometheus" {
  ami                    = "${data.aws_ami.ubuntu_bionic.id}"
  instance_type          = "${var.prometheus_instance_type}"
  subnet_id              = "${element(var.private_subnet_ids, 0)}"
  vpc_security_group_ids = ["${var.prometheus_security_group_id}"]

  iam_instance_profile = "${
    aws_iam_instance_profile.concourse_prometheus.name
  }"

  user_data = "${
    data.template_file.concourse_prometheus_cloud_init.rendered
  }"

  root_block_device {
    volume_size = 20
  }

  tags {
    Name       = "${var.deployment}-concourse-prometheus"
    Deployment = "${var.deployment}"
    Role       = "prometheus"
  }
}

resource "aws_ebs_volume" "concourse_prometheus" {
  size      = 100
  encrypted = true

  availability_zone = "${
    data.aws_subnet.concourse_prometheus.availability_zone
  }"

  tags = {
    Name       = "${var.deployment}-concourse-prometheus"
    Deployment = "${var.deployment}"
  }
}

resource "aws_volume_attachment" "concourse_prometheus_concourse_prometheus" {
  device_name = "/dev/xvdp"
  volume_id   = "${aws_ebs_volume.concourse_prometheus.id}"
  instance_id = "${aws_instance.concourse_prometheus.id}"
}

resource "aws_lb_target_group_attachment" "concourse_prometheus" {
  target_group_arn = "${aws_lb_target_group.concourse_prometheus.arn}"
  target_id        = "${aws_instance.concourse_prometheus.id}"
  port             = 9090
}
