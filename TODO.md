# TODO

- Deploying to S3/CloudFront: the prerendered routes only resolve correctly with a
  trailing slash (`/experience/`, not `/experience`). Need a CloudFront Function
  (viewer request) that appends `index.html` for extensionless paths so bare paths
  like `/experience` also serve the prerendered file instead of falling through.
- Update SEO copy (per-route titles/descriptions in `src/data/seo.ts`) — current
  text is a placeholder pass, not tuned for actual search terms.
