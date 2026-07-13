resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "${var.site_domain}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "index_rewrite" {
  name    = replace("${var.site_domain}-index-rewrite", ".", "-")
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = file("${path.module}/cloudfront-function.js")
  comment = "Appends /index.html for extensionless paths so prerendered routes resolve without a trailing slash."

  # When site_domain changes (e.g. a domain cutover), this function's name
  # changes too, forcing replacement. Without create_before_destroy, Terraform
  # destroys the old function first — but it's still attached to the
  # distribution at that point (the distribution hasn't been updated to
  # reference the new one yet), so AWS rejects the delete with
  # "FunctionInUse". This ensures the new function exists (and the
  # distribution can be updated to point at it) before the old one is torn
  # down.
  lifecycle {
    create_before_destroy = true
  }
}

# Preview/non-final domains should stay out of search results. Always
# created (not conditional on var.noindex) and only conditionally attached
# to the distribution below, deliberately: the distribution only references
# this resource inside `var.noindex ? ... : null`, so when count was
# conditional too, flipping noindex from true to false meant destroying
# this policy at the same time the distribution stopped referencing it —
# and since var.noindex is a statically-known value, Terraform prunes the
# unreached ternary branch as dead code and never builds a dependency edge
# to it. That leaves "update distribution to detach" and "destroy the
# policy" as unordered, independent operations, and AWS rejects the destroy
# if it runs first ("ResponseHeadersPolicyInUse"). Always creating this
# resource (harmless and free when unattached) avoids the ordering problem
# entirely, since it's never destroyed as part of a noindex flip.
moved {
  from = aws_cloudfront_response_headers_policy.noindex[0]
  to   = aws_cloudfront_response_headers_policy.noindex
}

resource "aws_cloudfront_response_headers_policy" "noindex" {
  name    = "${replace(var.site_domain, ".", "-")}-noindex"
  comment = "Blocks search indexing on ${var.site_domain}."

  custom_headers_config {
    items {
      header   = "X-Robots-Tag"
      value    = "noindex, nofollow, noarchive"
      override = true
    }
  }
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = local.domain_aliases
  price_class         = "PriceClass_100"

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-${var.site_domain}"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-${var.site_domain}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # Managed-CachingOptimized
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    response_headers_policy_id = var.noindex ? aws_cloudfront_response_headers_policy.noindex.id : null

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.index_rewrite.arn
    }
  }

  # SPA-style fallback for genuinely missing paths — the client-side router
  # takes over and renders a not-found state.
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.site.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}
