# This allows you to customise the naming of the components for 2 scenarios:
# 1. logging_suffix = [default], bucket_names_list = [default]
#     logs all buckets in account under a generic name
# 2. logging_suffix = specified, bucket_names_list = specified bucket ARNs.
#     logs specified buckets under a specific name
#     this is for logging a group of buckets that belong to the same service
#     or for logging a single bucket

locals {
  # for account id = 1234..2
  # if logging_suffix is default
  #   "s3-object-logging-1234..2"
  # else if logging_suffix = "my_application"
  #   "s3-object-logging-my-application"
  # snake case is converted to kebab case
  cloudtrail_name = "${
    var.logging_suffix == ""
    ? "s3-object-logging-${data.aws_caller_identity.current.account_id}"
    : "s3-object-logging-${replace(var.logging_suffix, "_", "-")}"
  }"

  # as above except account ID is always included in bucket name
  # because S3 bucket names must be globally unique.
  # if logging_suffix is default
  #   "s3-object-logging-1234..2"
  # else if logging_suffix = "my_application"
  #   "s3-object-logging-1234..2-my-application"
  # snake case is converted to kebab case
  cloudtrail_bucket_name = "${
    var.logging_suffix == ""
    ? "s3-object-logging-${data.aws_caller_identity.current.account_id}"
    : "s3-object-logging-${data.aws_caller_identity.current.account_id}-${replace(var.logging_suffix, "_", "-")}"
  }"

  # allow user to specify any tagging they like and then append our tags into the map.
  tags = merge(var.tags, map(
    "ModuleSource", "https://github.com/alphagov/tech-ops/tree/master/cyber-security/modules/csls_s3_object_logging",
    "ModuleOwner", "cyber.security@digital.cabinet-office.gov.uk"
  ))
}
