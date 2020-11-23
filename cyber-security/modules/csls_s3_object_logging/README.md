# CSLS S3 Object Level Logging

Configure object level logging on all buckets 
in an account or a named list of buckets. 

Subscribe the cloudtrail to the CSLS to deliver 
the logs to SplunkCloud. 

## Usage

```
module "s3_object_logging_test" {
  source                     = "git::https://github.com/alphagov/tech-ops.git//cyber-security/modules/csls_s3_object_logging?ref=0e9b21f2c1ecc9885f439194483d81733469f111"
  cloudwatch_destination_arn = "[ ask in #cyber-security-help ]"
  logging_suffix             = ""
  bucket_names_list          = [
    "my-1st-bucket",
    "my-2nd-bucket"
  ]
  tags =
    Add         = "your own"
    Tags        = "to tag all the"
    Created     = "resources"
  }
}

```  

### Module Variables

* `cloudwatch_destination_arn` (Required):  
    Ask in [#cyber-security-help](https://gds.slack.com/archives/CCMPJKFDK)
* `cloudwatch_filter_pattern` (Optional): 
    Filter events before sending to Splunk.
* `bucket_names_list` (Optional):  
    The default behaviour is to monitor all buckets in the account. 
* `logging_suffix` (Optional): 
    The default behaviour is to label things with the account ID.
    If you limit to specific buckets you should apply a name here. 
* `tags` (Optional): 
    A map of tags to apply to the deployed resources. 

