# CSLS S3 Object Level Logging

Configure object level logging on all buckets 
in an account or a named list of buckets. 

Subscribe the cloudtrail to the CSLS to deliver 
the logs to SplunkCloud. 

## Usage

```
module "s3_object_logging_test" {
  source                     = "git::https://github.com/alphagov/tech-ops.git//cyber-security/modules/csls_s3_object_logging?ref=0b93f642678d09f5f329f4ef6b1db0258ed8fec2"
  cloudwatch_destination_arn = "[ ask in #cyber-security-help ]"
  logging_suffix             = ""
  bucket_arn_list = [
    "arn:aws:s3:::my-1st-bucket/",
    "arn:aws:s3:::my-2nd-bucket/"
  ]
  tags = {
    Add         = "your own"
    Tags        = "to tag all the"
    Created     = "resources"
  }
}

```  

NOTE: If individual bucket ARNS are added they must be appended with a trailing slash.

### Module Variables

* `cloudwatch_destination_arn` (Required):  
    Ask in [#cyber-security-help](https://gds.slack.com/archives/CCMPJKFDK)
* `cloudwatch_filter_pattern` (Optional): 
    Filter events before sending to Splunk.
* `bucket_arn_list` (Optional):  
    The default behaviour is to monitor all buckets in the account. 
* `logging_suffix` (Optional): 
    The default behaviour is to label things with the account ID.
    If you limit to specific buckets you should apply a name here. 
* `tags` (Optional): 
    A map of tags to apply to the deployed resources. 

