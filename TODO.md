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
