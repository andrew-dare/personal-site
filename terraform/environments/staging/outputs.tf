output "site_url" {
  value = module.site.site_url
}

output "s3_bucket_name" {
  value = module.site.s3_bucket_name
}

output "cloudfront_distribution_id" {
  value = module.site.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  value = module.site.cloudfront_domain_name
}

output "github_deploy_role_arn" {
  description = "Set this as the AWS_DEPLOY_ROLE_ARN GitHub Actions variable for the staging deploy job."
  value       = module.site.github_deploy_role_arn
}
