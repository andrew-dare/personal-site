data "aws_route53_zone" "root" {
  name = var.root_domain
}

resource "aws_route53_record" "site" {
  zone_id = data.aws_route53_zone.root.zone_id
  name    = var.site_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}
