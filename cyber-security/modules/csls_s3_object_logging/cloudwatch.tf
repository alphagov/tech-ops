module s3_to_splunk {
  source                     = "../s3_to_splunk"
  cloudwatch_destination_arn = var.cloudwatch_destination_arn
  logging_suffix             = var.logging_suffix
  bucket_names_list          = var.bucket_names_list
  cloudwatch_filter_pattern  = var.cloudwatch_filter_pattern
  tags                       = local.tags
}
