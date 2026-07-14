# TODO

- Update SEO copy (per-route titles/descriptions in `src/data/seo.ts`) — current
  text is a placeholder pass, not tuned for actual search terms.
- `stg-new.dare.dev` is deliberately blocked from search indexing (a CloudFront
  `X-Robots-Tag: noindex` response header, `noindex = true` in its `site.tf`)
  since it's still a preview subdomain. `public/robots.txt`'s old blanket
  disallow-all was removed since it applied to every environment identically
  and would've incorrectly blocked the real production domain too — the
  CloudFront header is now the only search-blocking mechanism, and it's
  already environment-aware (`noindex = false` for production).
- Restrict who can trigger deploys, in case a collaborator/bot is ever added
  (nobody else has access today, so this is precautionary): add yourself as a
  required reviewer on both the `production` (staging) and `prod` (production)
  GitHub Environments, and add branch protection on `main` (require PRs,
  restrict direct pushes). Steps in `terraform/README.md` under "Restricting
  who can deploy".
- Migrate staging's live Terraform state into `environments/staging` (it's still
  tracked under the old flat `terraform/` root layout from before the
  module/environments split) and run `terraform apply` there to pick up the OIDC
  thumbprint fix below. Exact `terraform state mv` commands are in
  `terraform/README.md` under "Migrating staging's existing state".
- Fixed but not yet applied: the OIDC provider's thumbprint was pinned to
  GitHub's leaf TLS cert (`certificates[0]`), which is Let's Encrypt and rotates
  every ~90 days — it just rotated and broke every deploy with "The web identity
  token provided could not be validated." Now pinned to the root CA instead
  (`environments/staging/oidc.tf`), which is stable for decades. Needs
  `terraform apply` (see state migration item above) to take effect.
- Cutover to `environments/production` targeting `dare.dev` + `www.dare.dev`
  is in progress (attempted twice, partially applied both times). The
  alias-removal prerequisite was done correctly both times — every failure
  has been a real bug in `modules/site`, not something done wrong:
  - Attempt 1: `FunctionInUse` / `ResponseHeadersPolicyInUse` /
    `BucketNotEmpty`. Fixed the CloudFront Function
    (`create_before_destroy`) and added `force_destroy` to the S3 bucket.
  - Attempt 2 (after that fix): `ResponseHeadersPolicyInUse` /
    `BucketNotEmpty` again. The response headers policy is now always
    created (not conditional on `noindex`) and only conditionally attached,
    with a `moved` block to rename the existing instance in place instead
    of destroying and recreating it — confirmed via `terraform plan`
    against live state that this is now a pure in-place rename (`id`
    unchanged), no destroy involved at all.
  - `force_destroy` still didn't empty the old `prod-new.dare.dev` bucket:
    confirmed via `terraform state show` that this bucket's state still has
    `force_destroy = false` recorded from before the fix, and a replace
    destroys the old instance using its last-applied config, not the new
    one — `force_destroy` only takes effect for buckets created with it
    from the start. This one bucket needs manually emptying first
    (`aws s3 rm s3://prod-new.dare.dev --recursive`) before the next
    `apply`; not done in this session.
  - Re-running `apply` after these fixes not attempted in this session.
- After the cutover apply, update the `PROD_*` GitHub Actions repository
  variables (bucket name and IAM role ARN both change, since they're derived
  from the domain name) so `.github/workflows/deploy-production.yml`
  (manual, `workflow_dispatch`) can actually deploy it. None are set yet.
- The old `dare.dev`/`www.dare.dev` CloudFront distribution (`E2RT0VQHJ1X6SV`)
  and its S3 website bucket are being left alone for now, per an explicit
  decision — DNS will simply stop pointing at them once the cutover above
  happens, leaving them orphaned but harmless (small ongoing cost).
  Decommission them as a separate, deliberate step once the new site is
  confirmed working.
- GitHub Environments renamed to their correct names: staging's
  `deploy.yml` job now uses `environment: staging` (was `production`),
  production's `deploy-production.yml` now uses `environment: production`
  (was `prod`) — matched by `github_deploy_environment` in each stack's
  `site.tf`. **Requires reapplying both stacks before this is safe to
  merge, not after** — each IAM role's OIDC trust policy only accepts the
  *old* environment name until reapplied, and staging's `deploy.yml` runs
  automatically on every push to `main`, including the push that merges
  this very change. Reapply staging first (confirmed via `terraform plan`:
  updates the trust policy's `sub` condition from `environment:production`
  to `environment:staging`, 1 to add/4 to change/1 to destroy — the rest is
  pre-existing drift from earlier unapplied changes, not new from this),
  then merge. Production isn't live yet regardless, so its rename carries
  no timing risk — just bundled into the same still-pending cutover apply.
  The old `production` (staging's) and `prod` (production's) GitHub
  Environments will be left behind as unused entries in Settings →
  Environments once the new names are in use — delete them there manually
  whenever, low priority.
- Set up Cloudflare Web Analytics to actually get traffic data: create the
  site(s) in the Cloudflare dashboard (Analytics & Logs → Web Analytics —
  doesn't require DNS to be on Cloudflare) and set the resulting token(s) as
  `CF_BEACON_TOKEN` / `PROD_CF_BEACON_TOKEN` GitHub Actions variables. The
  code side is done (`src/analytics.ts`, wired into both deploy workflows) —
  this is the one manual step left, since it needs a Cloudflare account.
  Details in `terraform/README.md` under "Analytics".
