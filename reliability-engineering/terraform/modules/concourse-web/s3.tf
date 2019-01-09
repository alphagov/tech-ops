resource "random_string" "concourse_web_s3_bucket_offset" {
  length  = 6
  special = false
  upper   = false
  number  = false
}

resource "aws_s3_bucket" "concourse_web" {
  bucket = "${var.deployment}-concourse-web-${random_string.concourse_web_s3_bucket_offset.result}"
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}
