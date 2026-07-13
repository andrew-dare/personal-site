module "site" {
  source = "../../modules/site"
  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  site_domain = "prod-new.dare.dev"
  root_domain = "dare.dev"

  github_repo          = "andrew-dare/personal-site"
  github_deploy_branch = "main"
  # No production deploy workflow exists yet. "production" is the correct
  # semantic name, but staging's *current* deploy.yml job is (confusingly)
  # also named "production" even though it deploys staging — see TODO.md.
  # Rename staging's environment to "staging" before wiring up a real prod
  # deploy job, or these two roles will both trust the same OIDC subject.
  github_deploy_environment = "production"

  oidc_provider_arn = data.aws_iam_openid_connect_provider.github.arn

  # prod-new.dare.dev is still a preview subdomain, not the final public
  # domain (e.g. www.dare.dev) — keep it out of search results until cutover.
  # Remove when this points at the real domain (tracked in TODO.md).
  noindex = true
}
