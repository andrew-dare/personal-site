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
  is in progress (attempted, partially applied). The alias-removal
  prerequisite was done correctly, but the apply itself failed partway with
  `ResponseHeadersPolicyInUse` / `FunctionInUse` / `BucketNotEmpty` errors —
  a real ordering bug in `modules/site`: the CloudFront Function needed
  `create_before_destroy` (fixed) and the S3 bucket needed `force_destroy`
  (fixed), so re-running `terraform apply` should now complete cleanly.
  `terraform plan` after the fix shows a much smaller, correctly-ordered
  diff (8 to add, 1 to change, 4 to destroy, including cleaning up one
  deposed ACM certificate object left over from the failed run). Re-running
  `apply` not attempted in this session.
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
- Staging's `deploy.yml` job is named `environment: production` even though it
  deploys the *staging* domain — a leftover from before the staging/production
  split. The new production workflow avoids colliding with it by using a
  distinct environment name (`prod` instead of `production`), which works fine
  as a permanent name, but if you'd rather have the "correct" name on the real
  production stack: rename staging's environment (in both `deploy.yml` and
  `environments/staging/site.tf`) to `"staging"`, reapply staging, then rename
  production's from `"prod"` to `"production"` and reapply. Not required.
- Set up Cloudflare Web Analytics to actually get traffic data: create the
  site(s) in the Cloudflare dashboard (Analytics & Logs → Web Analytics —
  doesn't require DNS to be on Cloudflare) and set the resulting token(s) as
  `CF_BEACON_TOKEN` / `PROD_CF_BEACON_TOKEN` GitHub Actions variables. The
  code side is done (`src/analytics.ts`, wired into both deploy workflows) —
  this is the one manual step left, since it needs a Cloudflare account.
  Details in `terraform/README.md` under "Analytics".
