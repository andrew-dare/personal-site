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
  # Deliberately not "production" — staging's deploy.yml job is (confusingly)
  # also named "production" even though it deploys staging (see TODO.md), and
  # reusing that name here would mean both stacks' IAM roles trust the same
  # OIDC subject. "prod" keeps this stack's trust policy distinct without
  # needing to coordinate a rename of staging's still-not-yet-reapplied setup.
  github_deploy_environment = "prod"

  oidc_provider_arn = data.aws_iam_openid_connect_provider.github.arn

  # prod-new.dare.dev is still a preview subdomain, not the final public
  # domain (e.g. www.dare.dev) — keep it out of search results until cutover.
  # Remove when this points at the real domain (tracked in TODO.md).
  noindex = true
}
