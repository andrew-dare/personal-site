# TODO

- Update SEO copy (per-route titles/descriptions in `src/data/seo.ts`) — current
  text is a placeholder pass, not tuned for actual search terms.
- `stg-new.dare.dev` and `prod-new.dare.dev` are both deliberately blocked from
  search indexing (`public/robots.txt` disallow-all + a CloudFront
  `X-Robots-Tag: noindex` response header in `terraform/modules/site/cloudfront.tf`,
  set via `noindex = true` in each stack's `site.tf`) — both are still preview
  subdomains, not the final public domain. Remove `robots.txt` and flip
  `noindex = false` once a stack points at the real, final domain.
- Restrict who can trigger the deploy workflow, in case a collaborator/bot is ever
  added (nobody else has access today, so this is precautionary): add yourself as a
  required reviewer on the `production` GitHub Environment, and add branch
  protection on `main` (require PRs, restrict direct pushes). Steps in
  `terraform/README.md` under "Restricting who can deploy".
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
- Build and apply `environments/production` (targets `prod-new.dare.dev`,
  written and `terraform plan`-verified clean — 14 resources to create, 0
  destroys — but not yet applied). No deploy workflow exists for it yet either;
  see the next item.
- Separate staging and production deployments properly. Today there's a single
  `deploy.yml` workflow and a single GitHub Environment named `production` that
  actually deploys to the `stg-new.dare.dev` *staging* domain on every push to
  `main`. Terraform now has two real, independent stacks
  (`terraform/environments/staging` and `.../production`), but there's still no
  production deploy workflow, and staging's GitHub Environment needs renaming to
  `"staging"` before one is added — both stacks currently trust the same
  `github_deploy_environment = "production"` OIDC subject, which only stays safe
  because no second workflow uses that name yet. Needs its own deploy job/workflow
  and a trigger that isn't just "push to main" so staging and production don't
  deploy in lockstep.
- Update favicon.
