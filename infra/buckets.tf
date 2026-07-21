# The apex bucket holds the site itself — the 1999-2003 mirror in site/ — and
# is private: CloudFront reads it through an origin access control (see
# cloudfront.tf). The www bucket is retained only to hold the name; www traffic
# is answered by CloudFront and 301'd to the apex by the router function.
#
# History: both buckets spent 2019-2026 as website-redirect buckets pointing at
# github.com/johncarmack1984. The redirect configs were removed when the site
# came back from the Wayback Machine.

# --- themiscpage.com (apex, site origin) ---

resource "aws_s3_bucket" "themiscpage_com" {
  bucket              = "themiscpage.com"
  bucket_namespace    = "global"
  force_destroy       = false
  object_lock_enabled = false
  region              = "us-west-1"
  tags                = {}
  tags_all            = {}
}

resource "aws_s3_bucket_public_access_block" "themiscpage_com" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = "themiscpage.com"
  ignore_public_acls      = true
  region                  = "us-west-1"
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "site_read" {
  statement {
    sid       = "CloudFrontRead"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.themiscpage_com.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "themiscpage_com" {
  bucket = aws_s3_bucket.themiscpage_com.id
  region = "us-west-1"
  policy = data.aws_iam_policy_document.site_read.json
}

# --- www.themiscpage.com (name reservation only) ---

resource "aws_s3_bucket" "www_themiscpage_com" {
  bucket              = "www.themiscpage.com"
  bucket_namespace    = "global"
  force_destroy       = false
  object_lock_enabled = false
  region              = "us-west-1"
  tags                = {}
  tags_all            = {}
}

resource "aws_s3_bucket_public_access_block" "www_themiscpage_com" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = "www.themiscpage.com"
  ignore_public_acls      = true
  region                  = "us-west-1"
  restrict_public_buckets = true
}
