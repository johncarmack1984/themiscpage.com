# Config-driven imports — the themiscpage.com apex + www redirect buckets and
# their sub-resources, moved out of my-infra/storage into this dedicated private
# repo 2026-06-12.

# --- themiscpage.com (us-west-1) ---

import {
  to = aws_s3_bucket.themiscpage_com
  id = "themiscpage.com"
}

import {
  to = aws_s3_bucket_public_access_block.themiscpage_com
  id = "themiscpage.com"
}

import {
  to = aws_s3_bucket_website_configuration.themiscpage_com
  id = "themiscpage.com"
}

# --- www.themiscpage.com (us-west-1) ---

import {
  to = aws_s3_bucket.www_themiscpage_com
  id = "www.themiscpage.com"
}

import {
  to = aws_s3_bucket_website_configuration.www_themiscpage_com
  id = "www.themiscpage.com"
}
