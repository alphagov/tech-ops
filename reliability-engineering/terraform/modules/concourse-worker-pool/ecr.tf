data "aws_iam_role" "concourse_worker" {
  name = "${var.worker_iam_role_name}"
}

resource "random_string" "concourse_worker_private_ecr_repo" {
  length  = 6
  special = false
  upper   = false
  number  = false
}

resource "aws_ecr_repository" "concourse_worker_private" {
  name = "${ join("-", list(
    var.deployment, var.name, "private",
    random_string.concourse_worker_private_ecr_repo.result
  ))}"

  tags {
    Deployment = "${var.deployment}"
  }
}

resource "aws_ecr_lifecycle_policy" "concourse_worker_private_last_900" {
  repository = "${aws_ecr_repository.concourse_worker_private.name}"

  policy = <<-POLICY
  {
    "rules": [
      {
        "rulePriority": 1,
        "description": "Keep only last 900 images",
        "selection": {
          "tagStatus": "untagged",
          "countType": "imageCountMoreThan",
          "countNumber": 900
        },
        "action": {
          "type": "expire"
        }
      }
    ]
  }
  POLICY
}

resource "aws_ecr_repository_policy" "concourse_worker_private" {
  repository = "${aws_ecr_repository.concourse_worker_private.name}"

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Principal": {
        "AWS": ["${data.aws_iam_role.concourse_worker.arn}"]
      }
    }]
  }
  EOF
}
