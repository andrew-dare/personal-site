# Infrastructure

Provisions `stg-new.dare.dev`: a private S3 bucket served through CloudFront
(via Origin Access Control, no public bucket), an ACM certificate, a Route53
alias record, and a GitHub Actions OIDC deploy role — no long-lived AWS keys
in CI.

Applied and live under the `dare-dev` AWS profile. State is local
(`terraform.tfstate`, gitignored) — see [State](#state) below.

## One-time setup

1. Point Terraform at the AWS profile for the account that owns the
   `dare.dev` Route53 zone. Either:
   - copy `terraform.tfvars.example` to `terraform.tfvars` and set
     `aws_profile`, or
   - export it as an environment variable instead of using a tfvars file:
     ```
     export TF_VAR_aws_profile=<profile-name>
     ```
   Terraform itself takes no other required variables — `site_domain`,
   `root_domain`, `github_repo`, and `github_deploy_branch` all have sensible
   defaults in `variables.tf` and only need overriding if any of those change.
   Actual AWS auth comes from that profile's entry in `~/.aws/credentials` —
   no `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` env vars needed locally.
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

## Restricting who can deploy

Today only `andrew-dare` has write access to the repo and there's no branch
protection on `main`, so nobody else can trigger `.github/workflows/deploy.yml`
— it only runs on push to `main`, and pushing/merging there requires write
access. The OIDC trust policy in `iam-github-oidc.tf` also scopes the deploy
role to `repo:andrew-dare/personal-site:ref:refs/heads/main` specifically, so
no other repo, fork, or branch can assume it regardless of GitHub-side
permissions.

If a collaborator, bot, or automation is ever added, harden this further
(these are access-control changes on the GitHub repo itself, so do them
directly rather than scripted):

1. **Require manual approval on every deploy** — Settings → Environments →
   `production` → enable **Required reviewers** → add yourself. The workflow
   already declares `environment: name: production`; this makes every run
   pause until you personally approve it, independent of who or what pushed
   to `main`.
2. **Lock down `main`** — Settings → Branches → Add branch protection rule
   for `main` → enable **Require a pull request before merging** and
   **Restrict who can push to matching branches** (limit to yourself).

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
