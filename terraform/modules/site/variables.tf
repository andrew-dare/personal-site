variable "site_domain" {
  description = "Primary domain this environment is served from — used for the ACM certificate's common name, tags, and default bucket name."
  type        = string
}

variable "domain_aliases" {
  description = "All domains this distribution should respond to (CloudFront aliases + ACM subject alternative names + a Route53 record per domain). Defaults to just [site_domain]."
  type        = list(string)
  default     = null
}

variable "bucket_name" {
  description = "S3 bucket name. Defaults to site_domain — override when that exact name is already taken globally (e.g. by pre-existing infrastructure for the same domain)."
  type        = string
  default     = null
}

variable "root_domain" {
  description = "Root domain of the existing Route53 hosted zone (must already exist)."
  type        = string
}

variable "github_repo" {
  description = "GitHub repo allowed to assume the deploy role, as \"owner/repo\"."
  type        = string
}

variable "github_deploy_branch" {
  description = "Branch the deploy role may be assumed from."
  type        = string
}

variable "github_deploy_environment" {
  description = "GitHub Actions environment name used by the deploy job for this stack (must match the `environment:` value in the relevant deploy workflow)."
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the (account-wide, shared) GitHub Actions OIDC provider. Only one may exist per AWS account — see environments/*/oidc.tf."
  type        = string
}

variable "noindex" {
  description = "Block search engine indexing via robots headers (for non-production/preview domains)."
  type        = bool
  default     = false
}
