# TODO

- Update SEO copy (per-route titles/descriptions in `src/data/seo.ts`) — current
  text is a placeholder pass, not tuned for actual search terms.
- `stg-new.dare.dev` and `prod-new.dare.dev` are both deliberately blocked from
  search indexing (`public/robots.txt` disallow-all + a CloudFront
  `X-Robots-Tag: noindex` response header in `terraform/modules/site/cloudfront.tf`,
  set via `noindex = true` in each stack's `site.tf`) — both are still preview
  subdomains, not the final public domain. Remove `robots.txt` and flip
  `noindex = false` once a stack points at the real, final domain.
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
- `environments/production` is applied and live (`terraform plan` shows "No
  changes"). Still need to set the `PROD_*` GitHub Actions repository
  variables listed in `terraform/README.md` (none are set yet — only
  staging's unprefixed ones are) so `.github/workflows/deploy-production.yml`
  (manual, `workflow_dispatch`) can actually deploy it.
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
