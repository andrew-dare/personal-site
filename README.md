# dare.dev

Personal site — Vite + React + TypeScript + React Router, prerendered to
static HTML per route for SEO, hosted on S3/CloudFront.

## Development

```
yarn install
yarn dev
```

## Build

```
yarn build
```

Runs `tsc`, the client build, an SSR build, then prerenders each route to
static HTML (see `scripts/prerender.mjs`). Output lands in `dist/`, ready to
upload as-is to a static host.

## Deployment

The site deploys to `stg-new.dare.dev` on S3/CloudFront, provisioned by
Terraform, with GitHub Actions handling the actual deploys.

### Terraform setup

Full details in [`terraform/README.md`](terraform/README.md). The short
version — Terraform needs to know which AWS profile owns the `dare.dev`
Route53 zone:

```
export TF_VAR_aws_profile=<profile-name>
```

(or copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars`
and set `aws_profile` there instead). No other variables are required —
everything else in `terraform/variables.tf` has a working default. AWS auth
itself comes from that profile in `~/.aws/credentials`, not from
`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` env vars.

```
cd terraform
terraform init
terraform plan
terraform apply
```

### Required GitHub Actions variables (for CD)

`.github/workflows/deploy.yml` deploys automatically on every push to `main`
(including PR merges). It needs these set as repository **variables**
(Settings → Secrets and variables → Actions → Variables on
`andrew-dare/personal-site`), populated from the Terraform outputs after
`terraform apply`:

| Variable                    | Source                                        |
| ---------------------------- | ---------------------------------------------- |
| `AWS_DEPLOY_ROLE_ARN`        | `terraform output github_deploy_role_arn`       |
| `AWS_REGION`                 | `var.aws_region` (default `us-east-1`)          |
| `S3_BUCKET_NAME`              | `terraform output s3_bucket_name`               |
| `CLOUDFRONT_DISTRIBUTION_ID`  | `terraform output cloudfront_distribution_id`   |
| `SITE_URL`                    | `terraform output site_url`                     |

No AWS secrets are stored in GitHub — the workflow authenticates via OIDC,
assuming the `AWS_DEPLOY_ROLE_ARN` role, which Terraform scopes to this
repo's `main` branch only.
