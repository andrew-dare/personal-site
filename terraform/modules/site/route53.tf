data "aws_route53_zone" "root" {
  name = var.root_domain
}

resource "aws_route53_record" "site" {
  for_each = toset(local.domain_aliases)

  zone_id = data.aws_route53_zone.root.zone_id
  name    = each.value
  type    = "A"

  # This domain may already have an A record (e.g. cutting a production
  # domain over from previous, non-Terraform-managed infrastructure) —
  # take it over rather than failing on "already exists". Existing MX/TXT/
  # other record types for the zone are untouched; this only ever manages a
  # single A record per domain in domain_aliases.
  allow_overwrite = true

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}
