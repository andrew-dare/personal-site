# Infrastructure

Two independent stacks, each provisioning the same shape of infrastructure —
a private S3 bucket served through CloudFront (via Origin Access Control, no
public bucket), an ACM certificate, a Route53 alias record, and a GitHub
Actions OIDC deploy role (no long-lived AWS keys in CI) — for a different
domain:

- `environments/staging` → `stg-new.dare.dev` (applied and live)
- `environments/production` → `prod-new.dare.dev` (written, not yet applied)

Both share resource definitions via `modules/site`. The GitHub Actions OIDC
provider is account-wide (AWS allows only one per URL), so `staging` owns
creating it and `production` looks it up via a data source — see
`environments/*/oidc.tf`.

Both `prod-new.dare.dev` and `stg-new.dare.dev` are still preview subdomains,
not the final public domain, so both are deliberately blocked from search
indexing (`noindex = true` in each stack's `site.tf`). Remove that — and
`public/robots.txt` at the repo root — once a stack points at the real,
final domain. Tracked in `TODO.md`.

## One-time setup (either stack)

From `environments/staging/` or `environments/production/`:

1. Point Terraform at the AWS profile for the account that owns the
   `dare.dev` Route53 zone. `aws_profile` has no default and is required —
   Terraform will refuse to run without it, rather than silently falling
   back to whatever your ambient default AWS credentials happen to be (which
   previously caused a confusing "OIDC Provider ... not found" error against
   a completely unrelated AWS account). Either:
   - copy `terraform.tfvars.example` to `terraform.tfvars` and set
     `aws_profile`, or
   - export it as an environment variable instead:
     ```
     export TF_VAR_aws_profile=<profile-name>
     ```
   No other variables are required — `aws_region` (optional, defaults to
   `us-east-1`) and `aws_profile` are the only ones exposed at this level;
   everything else (domain, GitHub repo, noindex, etc.) is set explicitly in
   that stack's `site.tf`.
2. `terraform init`
3. `terraform plan` — review before applying anything.
4. `terraform apply`

If the target AWS account already has a GitHub Actions OIDC provider
(`token.actions.githubusercontent.com`) from something unrelated to this
project, remove the `aws_iam_openid_connect_provider.github` resource from
`environments/staging/oidc.tf` and import the existing one instead — only
one is allowed per account:

```
terraform import aws_iam_openid_connect_provider.github \
  arn:aws:iam::<account-id>:oidc-provider/token.actions.githubusercontent.com
```

## Migrating staging's existing state

Staging was originally a single flat config directly in `terraform/` before
it was split into `modules/site` + `environments/staging`. The live state
(`terraform.tfstate` at the `terraform/` root, gitignored) still uses the old
flat resource addresses — `terraform apply` in `environments/staging` won't
recognize the already-applied resources as-is, and would try to create
duplicates (and fail, since the S3 bucket/domain/etc. already exist).

Move each resource into the new state with `terraform state mv`. Run from
`environments/staging` after `terraform init` there:

```
cd environments/staging

terraform state mv -state=../../terraform.tfstate -state-out=terraform.tfstate \
  'aws_iam_openid_connect_provider.github' 'aws_iam_openid_connect_provider.github'

terraform state mv -state=../../terraform.tfstate -state-out=terraform.tfstate \
  'aws_s3_bucket.site' 'module.site.aws_s3_bucket.site'
terraform state mv -state=../../terraform.tfstate -state-out=terraform.tfstate \
  'aws_s3_bucket_public_access_block.site' 'module.site.aws_s3_bucket_public_access_block.site'
terraform state mv -state=../../terraform.tfstate -state-out=terraform.tfstate \
  'aws_s3_bucket_ownership_controls.site' 'module.site.aws_s3_bucket_ownership_controls.site'
terraform state mv -state=../../terraform.tfstate -state-out=terraform.tfstate \
  'aws_s3_bucket_policy.site' 'module.site.aws_s3_bucket_policy.site'

terraform state mv -state=../../terraform.tfstate -state-out=terraform.tfstate \
  'aws_acm_certificate.site' 'module.site.aws_acm_certificate.site'
terraform state mv -state=../../terraform.tfstate -state-out=terraform.tfstate \
  'aws_acm_certificate_validation.site' 'module.site.aws_acm_certificate_validation.site'
terraform state mv -state=../../terraform.tfstate -state-out=terraform.tfstate \
  'aws_route53_record.cert_validation["stg-new.dare.dev"]' 'module.site.aws_route53_record.cert_validation["stg-new.dare.dev"]'
terraform state mv -state=../../terraform.tfstate -state-out=terraform.tfstate \
  'aws_route53_record.site' 'module.site.aws_route53_record.site'

terraform state mv -state=../../terraform.tfstate -state-out=terraform.tfstate \
  'aws_cloudfront_origin_access_control.site' 'module.site.aws_cloudfront_origin_access_control.site'
terraform state mv -state=../../terraform.tfstate -state-out=terraform.tfstate \
  'aws_cloudfront_function.index_rewrite' 'module.site.aws_cloudfront_function.index_rewrite'
terraform state mv -state=../../terraform.tfstate -state-out=terraform.tfstate \
  'aws_cloudfront_response_headers_policy.noindex' 'module.site.aws_cloudfront_response_headers_policy.noindex[0]'
terraform state mv -state=../../terraform.tfstate -state-out=terraform.tfstate \
  'aws_cloudfront_distribution.site' 'module.site.aws_cloudfront_distribution.site'

terraform state mv -state=../../terraform.tfstate -state-out=terraform.tfstate \
  'aws_iam_role.github_deploy' 'module.site.aws_iam_role.github_deploy'
terraform state mv -state=../../terraform.tfstate -state-out=terraform.tfstate \
  'aws_iam_role_policy.github_deploy' 'module.site.aws_iam_role_policy.github_deploy'
```

(Data sources — `data.aws_route53_zone.root`, `data.tls_certificate.github`,
the `data.aws_iam_policy_document.*` ones — don't need moving; they're
recomputed fresh on the next plan.)

Then verify before trusting it: `terraform plan` in `environments/staging`
should show **no changes**. If it doesn't, stop and figure out why before
applying anything — don't just apply to "fix" an unexpected diff.

Once confirmed clean, delete the old root-level `terraform.tfstate`,
`terraform.tfstate.backup`, `terraform.tfvars`, and `.terraform/` — they're
gitignored so this doesn't touch the repo, just the leftover local files.

## After applying

Each stack has its own outputs and its own set of GitHub Actions repository
**variables** (Settings → Secrets and variables → Actions → Variables) on
`andrew-dare/personal-site`. Staging's are unprefixed (`.github/workflows/deploy.yml`);
production's are `PROD_`-prefixed (`.github/workflows/deploy-production.yml`)
so the two can't be confused or accidentally left pointing at each other:

**Staging** — from `environments/staging`:

| Variable                     | Value                                           |
| ----------------------------- | ------------------------------------------------ |
| `AWS_DEPLOY_ROLE_ARN`         | `terraform output github_deploy_role_arn`         |
| `AWS_REGION`                  | value of `var.aws_region` (default `us-east-1`)   |
| `S3_BUCKET_NAME`              | `terraform output s3_bucket_name`                 |
| `CLOUDFRONT_DISTRIBUTION_ID`  | `terraform output cloudfront_distribution_id`     |
| `SITE_URL`                    | `terraform output site_url`                       |
| `CF_BEACON_TOKEN`             | *(optional)* Cloudflare Web Analytics site token — see "Analytics" below |

**Production** — from `environments/production`:

| Variable                          | Value                                           |
| ----------------------------------- | ------------------------------------------------ |
| `PROD_AWS_DEPLOY_ROLE_ARN`         | `terraform output github_deploy_role_arn`         |
| `PROD_AWS_REGION`                  | value of `var.aws_region` (default `us-east-1`)   |
| `PROD_S3_BUCKET_NAME`              | `terraform output s3_bucket_name`                 |
| `PROD_CLOUDFRONT_DISTRIBUTION_ID`  | `terraform output cloudfront_distribution_id`     |
| `PROD_SITE_URL`                    | `terraform output site_url`                       |
| `PROD_CF_BEACON_TOKEN`             | *(optional)* Cloudflare Web Analytics site token — see "Analytics" below |

## Analytics

The site loads [Cloudflare Web Analytics](https://www.cloudflare.com/web-analytics/)
(`src/analytics.ts`) — cookieless, no consent banner needed, single script
tag. It's entirely opt-in per environment: with no token set, Vite dead-code
eliminates the loader entirely at build time (nothing added to the bundle,
nothing requested at runtime).

To enable it for an environment:

1. In the Cloudflare dashboard, add the site under Analytics & Logs → Web
   Analytics (this doesn't require the domain's DNS to be on Cloudflare —
   Web Analytics works via the JS snippet alone) and copy its token.
2. Set it as `CF_BEACON_TOKEN` (staging) or `PROD_CF_BEACON_TOKEN`
   (production) in GitHub Actions repository variables.
3. Redeploy — the token is baked in at build time (`VITE_CF_BEACON_TOKEN`,
   passed by each workflow's Build step).

Nothing requires the same token (or any token at all) for both
environments — e.g. you might only want production tracked, so staging/dev
traffic doesn't muddy real numbers.

## Deploying to production

`.github/workflows/deploy-production.yml` is **manual only**
(`workflow_dispatch`) — it never runs on push, so merging to `main` never
touches production by itself. Run it from the repo's Actions tab (or
`gh workflow run deploy-production.yml`) once `environments/production` is
applied and the `PROD_*` variables above are set.

The job declares `environment: name: prod` — deliberately distinct from
staging's `environment: name: production` (itself a leftover from before the
staging/production split, since that job actually deploys the *staging*
domain). Reusing the same name would mean both stacks' IAM roles trust the
same OIDC subject, so anyone who could edit either workflow file could point
it at the other stack's AWS resources without IAM noticing. Once staging's
naming gets cleaned up (see `TODO.md`), consider renaming `prod` back to
`production` for clarity — not required, `prod` works fine as a permanent
name too.

## Restricting who can deploy

Today only `andrew-dare` has write access to the repo and there's no branch
protection on `main`, so nobody else can trigger either workflow: staging
only runs on push to `main`, production only runs when someone manually
dispatches it — both require write access either way. Each stack's OIDC
trust policy also scopes its deploy role to `repo:andrew-dare/personal-site`,
so no other repo or fork can assume it regardless of GitHub-side permissions.

If a collaborator, bot, or automation is ever added, harden this further
(these are access-control changes on the GitHub repo itself, so do them
directly rather than scripted):

1. **Require manual approval on every deploy** — Settings → Environments →
   `production` (staging) and `prod` (production) → enable **Required
   reviewers** on each → add yourself. This makes every run pause until you
   personally approve it, independent of who or what triggered it —
   redundant with production already being manual-dispatch-only, but useful
   if staging's automatic push-to-deploy trigger ever feels too loose.
2. **Lock down `main`** — Settings → Branches → Add branch protection rule
   for `main` → enable **Require a pull request before merging** and
   **Restrict who can push to matching branches** (limit to yourself).

## State

Local state for now, one file per stack (`environments/*/terraform.tfstate`,
gitignored). Consider migrating each to its own S3 backend so state isn't
only on one machine:

```hcl
# in environments/<name>/main.tf
backend "s3" {
  bucket = "<a state bucket you create once, by hand or in a small bootstrap config>"
  key    = "dare-dev-2026/<name>/terraform.tfstate"
  region = "us-east-1"
}
```

then `terraform init -migrate-state`.
