# TODO

- Update SEO copy (per-route titles/descriptions in `src/data/seo.ts`) — current
  text is a placeholder pass, not tuned for actual search terms.
- `stg-new.dare.dev` is deliberately blocked from search indexing (`public/robots.txt`
  disallow-all + a CloudFront `X-Robots-Tag: noindex` response header in
  `terraform/cloudfront.tf`). When a real production domain/environment is added,
  remove both so the live site is actually indexable — don't just copy this config
  over.
- Restrict who can trigger the deploy workflow, in case a collaborator/bot is ever
  added (nobody else has access today, so this is precautionary): add yourself as a
  required reviewer on the `production` GitHub Environment, and add branch
  protection on `main` (require PRs, restrict direct pushes). Steps in
  `terraform/README.md` under "Restricting who can deploy".
- Run `terraform apply` to pick up the OIDC trust policy fix (`terraform/iam-github-oidc.tf`)
  — every deploy so far has failed with "Not authorized to perform
  sts:AssumeRoleWithWebIdentity" because the workflow's `environment: production`
  changes the OIDC subject claim and the trust policy didn't account for it.
- Separate staging and control (production) deployments. Today there's a single
  `deploy.yml` workflow and a single GitHub Environment named `production` that
  actually deploys to the `stg-new.dare.dev` staging domain on every push to
  `main` — there's no distinct pipeline/environment/promotion step for a real
  production deploy yet. Needs its own Terraform (or workspace) targeting the
  real domain, its own environment, and a deploy trigger that isn't just "push
  to main" so staging and production don't deploy in lockstep.
