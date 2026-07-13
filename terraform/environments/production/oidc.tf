# The GitHub Actions OIDC provider is account-wide and only one may exist
# per URL — it's created by the staging stack (environments/staging/oidc.tf).
# Look it up here rather than creating a duplicate.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}
