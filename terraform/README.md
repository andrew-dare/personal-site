# Infrastructure

Two independent stacks, each provisioning the same shape of infrastructure —
a private S3 bucket served through CloudFront (via Origin Access Control, no
public bucket), an ACM certificate, a Route53 alias record, and a GitHub
Actions OIDC deploy role (no long-lived AWS keys in CI) — for a different
domain:

- `environments/staging` → `stg-new.dare.dev` (applied and live)
- `environments/production` → `dare.dev` + `www.dare.dev`, the real public
  domain (written, not yet applied — see "Cutting production over to the
  real domain" below; it previously pointed at the preview subdomain
  `prod-new.dare.dev`)

Both share resource definitions via `modules/site`, which supports serving
multiple domains off one distribution: `site_domain` is the primary domain
(ACM cert CN, tags), `domain_aliases` is the full list of domains the
distribution should answer to (defaults to just `[site_domain]`), and
`bucket_name` lets the S3 bucket use a name independent of the domain, for
cases like this one where the domain name itself is already taken as a
bucket name by pre-existing infrastructure. The GitHub Actions OIDC provider
is account-wide (AWS allows only one per URL), so `staging` owns creating it
and `production` looks it up via a data source — see `environments/*/oidc.tf`.

`stg-new.dare.dev` is still a preview subdomain, not the final public
domain, so it's deliberately blocked from search indexing (`noindex = true`
in its `site.tf`) via a CloudFront response header. `environments/production`
now points at the real domain, so its `noindex` is `false`. Search-blocking
used to also rely on a blanket `public/robots.txt` (`Disallow: /`) — that's
been removed, since it applied identically to every environment and would
now incorrectly block the real production domain too; the per-stack
CloudFront header is the only search-blocking mechanism now, and it's
already environment-aware.

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

**Done** — kept here for reference, since the same pattern applies any time
a resource's addressing changes (e.g. the `moved` block story in
`modules/site/cloudfront.tf`) and someone needs to see how a prior one was
handled.

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
  'aws_cloudfront_response_headers_policy.noindex' 'module.site.aws_cloudfront_response_headers_policy.noindex'
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

## Cutting production over to the real domain

`environments/production` moved from `prod-new.dare.dev` to `dare.dev` +
`www.dare.dev` — the domain that's already live today, served by a
pre-existing CloudFront distribution and S3 website bucket that this
Terraform has never managed. That existing setup is being left alone
deliberately (per an explicit decision — see `TODO.md`), which creates one
hard constraint: **CloudFront will not let a new distribution claim an alias
that's still active on another distribution in the same account.**
`terraform plan` can't detect this ahead of time (it's an apply-time API
call), so `terraform apply` will fail outright on the alias step unless this
is done first:

1. In the CloudFront console (or via CLI), edit the existing distribution
   (currently `E2RT0VQHJ1X6SV`) and remove `dare.dev` and `www.dare.dev` from
   its **Alternate domain names (CNAMEs)**. This does not delete or disable
   the distribution or its S3 bucket — it only frees up the two domain names
   so a different distribution can claim them. Everything else about the
   old setup stays exactly as it is.
2. Empty the old bucket before applying:
   `aws s3 rm s3://prod-new.dare.dev --recursive`. The module sets
   `force_destroy = true` on the S3 bucket, but that only takes effect for
   buckets *created* with it — this bucket already existed beforehand, so
   Terraform destroys it using its last-applied config (`force_destroy =
   false`), not the new one. Confirm with `terraform state show
   'module.site.aws_s3_bucket.site' | grep force_destroy` if in doubt.
3. `terraform apply` in `environments/production`. This will:
   - Destroy the old `prod-new.dare.dev`-named resources (bucket, ACM cert,
     CloudFront function, IAM role — all uniquely named after the domain)
     and create equivalents for `dare.dev`
   - Take over the existing Route53 A records for `dare.dev` and
     `www.dare.dev` (`allow_overwrite = true` in `modules/site/route53.tf`
     handles this — they already exist, pointing at the old distribution,
     and Terraform will overwrite them to point at the new one)
   - Request and DNS-validate a new ACM certificate covering both domains
   - Rename the response headers policy in place rather than recreating it
     (a `moved` block handles this) — it's always created regardless of
     `noindex`, and only conditionally attached to the distribution, so
     flipping `noindex` never requires destroying and recreating it
4. Update the `PROD_*` GitHub Actions variables (see "After applying" below)
   — the bucket name and IAM role ARN both changed since they're derived
   from the domain name, which changed.

**Left untouched by any of this:** the zone's MX and TXT records (Google
Workspace email, SPF, site verification) — this Terraform only ever manages
a single A record per domain in `domain_aliases`, nothing broader. The old
CloudFront distribution and its S3 bucket also stay fully intact, just no
longer reachable via DNS — decommissioning them is a deliberate, separate
step for later (tracked in `TODO.md`), not part of this change.

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

The job declares `environment: name: production`, and staging's job
declares `environment: name: staging` — kept distinct on purpose. Reusing
the same name for both would mean both stacks' IAM roles trust the same
OIDC subject, so anyone who could edit either workflow file could point it
at the other stack's AWS resources without IAM noticing.

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
   `staging` and `production` → enable **Required reviewers** on each →
   add yourself. This makes every run pause until you
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
