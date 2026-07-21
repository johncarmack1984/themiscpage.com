# CloudFront-facing certificate (us-east-1). DNS records live in my-infra/dns
# by convention, so validation is a two-step apply: apply here, add the emitted
# validation CNAMEs there, then re-apply once the cert issues. The
# sentiment.themiscpage.com cert in sentiment-analyzer/infra is separate and
# untouched.

resource "aws_acm_certificate" "site" {
  provider                  = aws.use1
  domain_name               = "themiscpage.com"
  subject_alternative_names = ["www.themiscpage.com"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

output "acm_validation_records" {
  description = "Create these CNAMEs in my-infra/dns to validate the certificate."
  value = [
    for dvo in aws_acm_certificate.site.domain_validation_options : {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  ]
}
