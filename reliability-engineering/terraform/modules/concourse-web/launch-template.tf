data "aws_ami" "ubuntu_bionic" {
  most_recent = true

  # canonical
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

data "template_file" "concourse_web_cloud_init" {
  template = "${file("${path.module}/files/web-init.sh")}"

  vars {
    deployment               = "${var.deployment}"
    main_team_github_team    = "${var.main_team_github_team}"
    concourse_external_url   = "${aws_route53_record.concourse_public_deployment.fqdn}"
    concourse_db_url         = "${aws_route53_record.concourse_private_db.fqdn}"
    concourse_version        = "v4.2.2"
    concourse_sha1           = "c40f1b97bd45b9d52962616562bf6ff77731b542  concourse_linux_amd64"
  }
}

resource "aws_launch_template" "concourse_web" {
  name_prefix            = "${var.deployment}-concourse-web-"
  ebs_optimized          = true
  image_id               = "${data.aws_ami.ubuntu_bionic.id}"
  instance_type          = "${var.instance_type}"
  vpc_security_group_ids = ["${aws_security_group.concourse_web.id}"]

  user_data = "${
    base64encode(data.template_file.concourse_web_cloud_init.rendered)
  }"

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 50
    }
  }

  iam_instance_profile {
    name = "${aws_iam_instance_profile.concourse_web.name}"
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name       = "${var.deployment}-concourse-web"
      Deployment = "${var.deployment}"
    }
  }

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name       = "${var.deployment}-concourse-web"
      Deployment = "${var.deployment}"
    }
  }

  tags {
    Deployment = "${var.deployment}"
  }
}
