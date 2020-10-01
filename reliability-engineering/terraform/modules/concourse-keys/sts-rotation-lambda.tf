resource "aws_iam_role" "concourse_sts_rotation_lambda_execution" {
  name               = "${var.deployment}-sts-rotation-lambda-execution"
  assume_role_policy = <<-ARP
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow"
      }
    ]
  }
ARP
}

output "concourse_sts_rotation_lambda_role_name" {
  value = aws_iam_role.concourse_sts_rotation_lambda_execution.name
}
