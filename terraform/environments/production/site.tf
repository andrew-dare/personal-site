module "site" {
  source = "../../modules/site"
  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  site_domain    = "dare.dev"
  domain_aliases = ["dare.dev", "www.dare.dev"]
  root_domain    = "dare.dev"

  # "dare.dev" as a bucket name is already taken — it's the pre-existing,
  # non-Terraform-managed bucket behind the current live site. This bucket
  # is new and unrelated to it.
  bucket_name = "dare-dev-production-site"

  github_repo          = "andrew-dare/personal-site"
  github_deploy_branch = "main"
  # Deliberately not "production" — staging's deploy.yml job is (confusingly)
  # also named "production" even though it deploys staging (see TODO.md), and
  # reusing that name here would mean both stacks' IAM roles trust the same
  # OIDC subject. "prod" keeps this stack's trust policy distinct without
  # needing to coordinate a rename of staging's still-not-yet-reapplied setup.
  github_deploy_environment = "prod"

  oidc_provider_arn = data.aws_iam_openid_connect_provider.github.arn

  # This is now the real, final public domain — searchable.
  noindex = false
}
