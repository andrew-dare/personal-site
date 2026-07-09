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

variable "site_domain" {
  description = "Full domain the staging site is served from."
  type        = string
  default     = "stg-new.dare.dev"
}

variable "root_domain" {
  description = "Root domain of the existing Route53 hosted zone (must already exist)."
  type        = string
  default     = "dare.dev"
}

variable "github_repo" {
  description = "GitHub repo allowed to assume the deploy role, as \"owner/repo\"."
  type        = string
  default     = "andrew-dare/personal-site"
}

variable "github_deploy_branch" {
  description = "Branch the deploy role may be assumed from."
  type        = string
  default     = "main"
}
