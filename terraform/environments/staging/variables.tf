variable "aws_region" {
  description = "AWS region for the S3 bucket and non-global resources."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile pointing at the account that owns the dare.dev Route53 zone."
  type        = string
  # No default — without one, Terraform silently falls back to whatever your
  # ambient default AWS credentials are, which previously caused a confusing
  # "OIDC Provider ... not found" error against a completely unrelated AWS
  # account instead of a clear "no value for required variable" one.
}
