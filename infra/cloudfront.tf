# CloudFront in front of the private apex bucket. One viewer-request function
# (cf/router.js) does all the era emulation:
#
#   - maps archived CGI query strings onto their frozen S3 object keys
#   - 301s www to the apex
#   - 302s any non-GET/HEAD to /cgi-bin/error.html (the UBB license page —
#     posting has been down since roughly the second Bush administration)
#
# Objects the archive never had fall through to /404.html, which is the
# hosting provider's own IIS "The page cannot be found" page, served verbatim.

resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "themiscpage-com-site"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "router" {
  name    = "themiscpage-com-router"
  runtime = "cloudfront-js-2.0"
  comment = "1999 CGI emulation: query-string routing, www redirect, POST -> license page"
  publish = true
  code    = file("${path.module}/cf/router.js")
}

resource "aws_cloudfront_cache_policy" "static_site" {
  name        = "themiscpage-com-static"
  comment     = "Everything is immutable amber; query strings are folded into the URI by the router"
  default_ttl = 86400
  max_ttl     = 31536000
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  comment             = "themiscpage.com - the 1999 site, back from the Wayback Machine"
  aliases             = ["themiscpage.com", "www.themiscpage.com"]
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  http_version        = "http2and3"

  origin {
    domain_name              = aws_s3_bucket.themiscpage_com.bucket_regional_domain_name
    origin_id                = "s3-site"
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-site"
    viewer_protocol_policy = "redirect-to-https"
    # POST must reach the router function to earn its license-error redirect.
    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
    cache_policy_id = aws_cloudfront_cache_policy.static_site.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.router.arn
    }
  }

  # S3 REST origins answer missing keys with 403 when the caller can GetObject
  # but not ListBucket; both spellings mean "the page cannot be found".
  custom_error_response {
    error_code         = 403
    response_code      = 404
    response_page_path = "/404.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/404.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.site.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

output "cloudfront_domain" {
  description = "Point the apex + www ALIAS records here (my-infra/dns owns the records)."
  value       = aws_cloudfront_distribution.site.domain_name
}

output "cloudfront_distribution_id" {
  description = "For cache invalidations from the deploy workflow."
  value       = aws_cloudfront_distribution.site.id
}
