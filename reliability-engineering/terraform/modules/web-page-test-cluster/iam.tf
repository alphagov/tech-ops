# IAM
#
# The controller requires AWS permissions for managing EC2 instances and S3
# buckets. These have to be provided in the cloud-init as credentials.
#
# EC2 permissions are required for creating/deleting instances
# S3 permissions are for saving data and assets to be persistent

resource "aws_iam_user" "web_page_test_controller" {
  name = "${var.env}-controller"
  path = "/"
}

resource "aws_iam_access_key" "web_page_test_controller" {
  user = "${aws_iam_user.web_page_test_controller.name}"
}

resource "aws_iam_user_policy_attachment" "web_page_test_controller_ec2" {
  user       = "${aws_iam_user.web_page_test_controller.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_user_policy_attachment" "web_page_test_controller_s3" {
  user       = "${aws_iam_user.web_page_test_controller.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
