# Staging owns creation of the account-wide GitHub Actions OIDC provider
# (only one is allowed per AWS account, since the URL must be unique).
# Other environment stacks in this account must look it up via a data
# source instead of creating their own — see environments/production/oidc.tf.
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # Pin to the ROOT CA (last cert in the chain), not the leaf (certificates[0]).
  # The leaf is a Let's Encrypt cert that rotates every ~90 days — pinning to
  # it broke every deploy the first time it rotated ("The web identity token
  # provided could not be validated"). The root is stable for decades.
  thumbprint_list = [
    data.tls_certificate.github.certificates[length(data.tls_certificate.github.certificates) - 1].sha1_fingerprint
  ]
}
