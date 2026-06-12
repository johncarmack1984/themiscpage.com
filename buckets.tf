# Moved verbatim from my-infra/storage 2026-06-12 (config + state). The apex and
# www buckets for themiscpage.com — both are website-redirect buckets pointing at
# github.com/johncarmack1984 (the live sentiment app lives at
# sentiment.themiscpage.com, served by Zappa from the sentiment-analyzer repo).
# DNS records + the domain registration stay in my-infra/dns; the themiscpage.com
# ACM cert stays in sentiment-analyzer/infra.

# --- themiscpage.com (apex) ---

# __generated__ by Terraform from "themiscpage.com"
resource "aws_s3_bucket" "themiscpage_com" {
  bucket              = "themiscpage.com"
  bucket_namespace    = "global"
  force_destroy       = false
  object_lock_enabled = false
  region              = "us-west-1"
  tags                = {}
  tags_all            = {}
}

# __generated__ by Terraform from "themiscpage.com"
resource "aws_s3_bucket_public_access_block" "themiscpage_com" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = "themiscpage.com"
  ignore_public_acls      = true
  region                  = "us-west-1"
  restrict_public_buckets = true
}

# __generated__ by Terraform from "themiscpage.com"
resource "aws_s3_bucket_website_configuration" "themiscpage_com" {
  bucket = "themiscpage.com"
  region = "us-west-1"
  redirect_all_requests_to {
    host_name = "github.com/johncarmack1984"
  }
}

# --- www.themiscpage.com ---

# __generated__ by Terraform from "www.themiscpage.com"
resource "aws_s3_bucket" "www_themiscpage_com" {
  bucket              = "www.themiscpage.com"
  bucket_namespace    = "global"
  force_destroy       = false
  object_lock_enabled = false
  region              = "us-west-1"
  tags                = {}
  tags_all            = {}
}

# __generated__ by Terraform from "www.themiscpage.com"
resource "aws_s3_bucket_website_configuration" "www_themiscpage_com" {
  bucket = "www.themiscpage.com"
  region = "us-west-1"
  redirect_all_requests_to {
    host_name = "github.com/johncarmack1984"
    protocol  = "https"
  }
}
