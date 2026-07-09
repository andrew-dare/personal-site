# TODO

- Update SEO copy (per-route titles/descriptions in `src/data/seo.ts`) — current
  text is a placeholder pass, not tuned for actual search terms.
- `stg-new.dare.dev` is deliberately blocked from search indexing (`public/robots.txt`
  disallow-all + a CloudFront `X-Robots-Tag: noindex` response header in
  `terraform/cloudfront.tf`). When a real production domain/environment is added,
  remove both so the live site is actually indexable — don't just copy this config
  over.
