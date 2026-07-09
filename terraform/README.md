# Infrastructure

Provisions `stg-new.dare.dev`: a private S3 bucket served through CloudFront
(via Origin Access Control, no public bucket), an ACM certificate, a Route53
alias record, and a GitHub Actions OIDC deploy role — no long-lived AWS keys
in CI.

This has been written and `terraform validate`-checked but **not applied**.
`terraform plan` confirms the config is otherwise correct; it currently fails
at the Route53 zone lookup because the AWS profile used to write this doesn't
own the `dare.dev` zone. Point it at the right account before applying.

## One-time setup

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and set `aws_profile`
   to the AWS CLI profile for the account that owns the `dare.dev` Route53
   zone.
2. If that account already has a GitHub Actions OIDC provider
   (`token.actions.githubusercontent.com`), remove the
   `aws_iam_openid_connect_provider.github` resource from
   `iam-github-oidc.tf` and import the existing one instead — only one is
   allowed per account:
   ```
   terraform import aws_iam_openid_connect_provider.github \
     arn:aws:iam::<account-id>:oidc-provider/token.actions.githubusercontent.com
   ```
3. `terraform init`
4. `terraform plan` — review before applying anything.
5. `terraform apply`

## After applying

Set these as GitHub Actions repository **variables** (Settings → Secrets and
variables → Actions → Variables) on `andrew-dare/personal-site`, using the
Terraform outputs:

| Variable                     | Value                                  |
| ----------------------------- | --------------------------------------- |
| `AWS_DEPLOY_ROLE_ARN`         | `terraform output github_deploy_role_arn` |
| `AWS_REGION`                  | value of `var.aws_region` (default `us-east-1`) |
| `S3_BUCKET_NAME`              | `terraform output s3_bucket_name`       |
| `CLOUDFRONT_DISTRIBUTION_ID`  | `terraform output cloudfront_distribution_id` |
| `SITE_URL`                    | `terraform output site_url`             |

Once those are set, pushes to `main` (including PR merges) will build and
deploy automatically via `.github/workflows/deploy.yml`.

## State

Local state for now (`terraform.tfstate`, gitignored). Once the target
account is confirmed, consider migrating to an S3 backend so state isn't
only on one machine:

```hcl
# in main.tf
backend "s3" {
  bucket = "<a state bucket you create once, by hand or in a small bootstrap config>"
  key    = "dare-dev-2026/terraform.tfstate"
  region = "us-east-1"
}
```

then `terraform init -migrate-state`.
