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
}

# This is a staging domain — keep it out of search results entirely. Drop
# this policy (and its attachment below) once this Terraform is pointed at a
# real production domain, so the live site isn't accidentally deindexed too.
resource "aws_cloudfront_response_headers_policy" "noindex" {
  name    = "${replace(var.site_domain, ".", "-")}-noindex"
  comment = "Blocks search indexing on the ${var.site_domain} staging domain."

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
  aliases             = [var.site_domain]
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

    response_headers_policy_id = aws_cloudfront_response_headers_policy.noindex.id

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
