data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# If a GitHub Actions OIDC provider already exists in the target AWS account
# (only one is allowed per account, since the URL must be unique), delete this
# resource and instead `terraform import` the existing one:
#   terraform import aws_iam_openid_connect_provider.github \
#     arn:aws:iam::<account-id>:oidc-provider/token.actions.githubusercontent.com
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

data "aws_iam_policy_document" "github_deploy_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # The deploy workflow's job specifies `environment: production`, which
    # changes GitHub's OIDC subject claim from the ref-based form to
    # "repo:OWNER/REPO:environment:NAME" — trust policies that only match
    # the ref-based subject reject the actual token with "Not authorized to
    # perform sts:AssumeRoleWithWebIdentity". Allow both forms so this keeps
    # working whether or not the job declares an environment.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_repo}:ref:refs/heads/${var.github_deploy_branch}",
        "repo:${var.github_repo}:environment:${var.github_deploy_environment}",
      ]
    }
  }
}

resource "aws_iam_role" "github_deploy" {
  name               = "${replace(var.site_domain, ".", "-")}-github-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_deploy_trust.json
}

data "aws_iam_policy_document" "github_deploy_permissions" {
  statement {
    sid       = "ListAndLocateBucket"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = [aws_s3_bucket.site.arn]
  }

  statement {
    sid       = "SyncObjects"
    actions   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]
  }

  statement {
    sid       = "InvalidateCache"
    actions   = ["cloudfront:CreateInvalidation", "cloudfront:GetInvalidation"]
    resources = [aws_cloudfront_distribution.site.arn]
  }
}

resource "aws_iam_role_policy" "github_deploy" {
  name   = "deploy-permissions"
  role   = aws_iam_role.github_deploy.id
  policy = data.aws_iam_policy_document.github_deploy_permissions.json
}
