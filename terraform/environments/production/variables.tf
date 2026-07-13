variable "aws_region" {
  description = "AWS region for the S3 bucket and non-global resources."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile pointing at the account that owns the dare.dev Route53 zone."
  type        = string
  default     = null
}
