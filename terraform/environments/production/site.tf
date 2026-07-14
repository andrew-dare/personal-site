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
  # Matches the `environment:` value in .github/workflows/deploy-production.yml.
  github_deploy_environment = "production"

  oidc_provider_arn = data.aws_iam_openid_connect_provider.github.arn

  # This is now the real, final public domain — searchable.
  noindex = false
}
