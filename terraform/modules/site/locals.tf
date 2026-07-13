locals {
  domain_aliases = coalesce(var.domain_aliases, [var.site_domain])
  bucket_name    = coalesce(var.bucket_name, var.site_domain)
}
