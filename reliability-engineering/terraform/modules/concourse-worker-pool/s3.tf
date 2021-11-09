resource "random_string" "concourse_worker_private_s3_bucket_offset" {
  length  = 6
  special = false
  upper   = false
  number  = false
}

resource "aws_s3_bucket" "concourse_worker_private" {
  bucket = "${var.deployment}-${var.name}-private-${random_string.concourse_worker_private_s3_bucket_offset.result}"
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

output "concourse_worker_private_s3_bucket_arn" {
  value = aws_s3_bucket.concourse_worker_private.arn
}

resource "random_string" "concourse_worker_public_s3_bucket_offset" {
  length  = 6
  special = false
  upper   = false
  number  = false
}

resource "aws_s3_bucket" "concourse_worker_public" {
  bucket = "${var.deployment}-${var.name}-public-${random_string.concourse_worker_public_s3_bucket_offset.result}"
  acl    = "public-read"

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
