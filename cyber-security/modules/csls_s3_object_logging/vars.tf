variable "cloudwatch_destination_arn" {
  type        = string
  description = "Ask for the CSLS cloudwatch destination ARN in #cyber-security-help."
}

variable "cloudwatch_filter_pattern" {
  type        = string
  description = "Can be used to filter events if required."
  default     = ""
}

variable "bucket_names_list" {
  type        = list(string)
  description = "A list of bucket names that you want to log."
  default     = []
}

variable "logging_suffix" {
  type        = string
  description = "For partial logging this is appended to the trail, log bucket name and cloudwatch log group."
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to be applied to each resource."
  default     = {}
}

