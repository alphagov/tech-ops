resource "aws_codecommit_repository" "pool_resource" {
  repository_name = join(
    "-",
    [
      "pool-resource",
      var.deployment,
      var.name,
    ],
  )

  description = "Used for concourse pool resource"

  default_branch = "pool"

  tags = {
    Deployment = var.deployment
  }
}

resource "aws_iam_user" "codecommit" {
  name = "${var.deployment}-${var.name}-codecommit"
}

resource "aws_iam_policy" "codecommit" {
  name = "${var.deployment}-${var.name}-codecommit"

  policy = <<-POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "codecommit:GitPull",
          "codecommit:GitPush"
        ],
        "Effect": "Allow",
        "Resource": "${aws_codecommit_repository.pool_resource.arn}"
      }
    ]
  }
POLICY
}

resource "aws_iam_user_policy_attachment" "codecommit_codecommit" {
  user       = aws_iam_user.codecommit.name
  policy_arn = aws_iam_policy.codecommit.arn
}

resource "tls_private_key" "codecommit" {
  algorithm   = "RSA"
}

resource "aws_iam_user_ssh_key" "codecommit" {
  username   = aws_iam_user.codecommit.name
  encoding   = "SSH"
  public_key = tls_private_key.codecommit.public_key_openssh
}
