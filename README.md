# themiscpage-infra

**Private.** Terraform for the **themiscpage.com** apex + `www` S3 buckets (us-west-1)
— both website-redirect buckets pointing at `github.com/johncarmack1984`. Split out
of the account-wide `my-infra` repo 2026-06-12.

The live app lives at `sentiment.themiscpage.com` (a Zappa Flask app deployed from the
`sentiment-analyzer` repo); these apex/www buckets just redirect the bare domain.

## What it manages

- `aws_s3_bucket.themiscpage_com` + PAB + website redirect
- `aws_s3_bucket.www_themiscpage_com` + website redirect

## Owned elsewhere (by convention)

- DNS records + the `themiscpage.com` domain registration → `my-infra/dns`
- the `themiscpage.com` ACM certificate + the sentiment app → `sentiment-analyzer/infra`

## Usage

```sh
export AWS_PROFILE=<admin-profile>
terraform init
terraform plan   # must report: No changes
```

State: `s3://john-carmack-terraform-state/themiscpage/terraform.tfstate`.
