data "aws_iam_policy_document" "github_deploy_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # A job that specifies `environment: NAME` gets an OIDC subject claim of
    # "repo:OWNER/REPO:environment:NAME" instead of the ref-based
    # "repo:OWNER/REPO:ref:refs/heads/BRANCH" — trust policies that only
    # match one form reject the token from a job using the other. Allow both
    # so this keeps working regardless of how the deploy job is set up.
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
