resource "aws_cloudtrail" "s3_object_logging_trail" {
  name                          = local.cloudtrail_name
  s3_bucket_name                = local.cloudtrail_bucket_name
  include_global_service_events = false

  tags = merge(local.tags, map("Name", local.cloudtrail_name))

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = [join("", ["arn:aws:s3:::", var.bucket_arn, "/"])]
    }
  }
}
