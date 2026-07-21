# Config-driven imports — the themiscpage.com apex + www buckets, moved out of
# my-infra/storage into this repo 2026-06-12. The website-redirect
# configurations they carried from 2019-2026 were removed (not re-imported)
# when the buckets became the site origin; see buckets.tf.

# --- themiscpage.com (us-west-1) ---

import {
  to = aws_s3_bucket.themiscpage_com
  id = "themiscpage.com"
}

import {
  to = aws_s3_bucket_public_access_block.themiscpage_com
  id = "themiscpage.com"
}

# --- www.themiscpage.com (us-west-1) ---

import {
  to = aws_s3_bucket.www_themiscpage_com
  id = "www.themiscpage.com"
}
