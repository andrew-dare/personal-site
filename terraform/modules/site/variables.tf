variable "site_domain" {
  description = "Full domain this environment is served from."
  type        = string
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
