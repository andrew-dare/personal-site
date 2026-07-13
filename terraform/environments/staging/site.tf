module "site" {
  source = "../../modules/site"
  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  site_domain = "stg-new.dare.dev"
  root_domain = "dare.dev"

  github_repo          = "andrew-dare/personal-site"
  github_deploy_branch = "main"
  # Matches the `environment:` value in .github/workflows/deploy.yml. Note
  # this is misleadingly named "production" today even though it deploys
  # staging — see TODO.md re: separating staging/production deploys.
  github_deploy_environment = "production"

  oidc_provider_arn = aws_iam_openid_connect_provider.github.arn

  # Still a preview subdomain, not the final public site — keep it out of
  # search results.
  noindex = true
}
