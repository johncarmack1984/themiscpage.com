# CI for this repo: a plan-only role and a site-deploy role for GitHub Actions
# in johncarmack1984/themiscpage.com (renamed from themiscpage-infra 2026-07;
# the state key keeps the old name). Both reuse the OIDC provider created by
# the public my-infra/github-oidc root (one provider per account), referenced
# here as a data source.
#
# The plan role uses the AWS-managed ReadOnlyAccess policy for the plan
# refresh plus narrow read on just this repo's Terraform state. It cannot
# apply. The deploy role is assumable only from main and can only sync the
# site bucket + invalidate CloudFront.

locals {
  github_repo  = "johncarmack1984/themiscpage.com"
  state_bucket = "john-carmack-terraform-state"
  site_bucket  = "themiscpage.com"

  # This repo's single root. The github-oidc root's own state key
  # (github-oidc-themiscpage-infra) is intentionally excluded — CI does not plan
  # itself.
  planned_state_keys = ["themiscpage"]
}

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${local.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "plan" {
  name                 = "github-actions-themiscpage-infra-plan"
  description          = "Plan-only role for GitHub Actions in ${local.github_repo} (OIDC)"
  assume_role_policy   = data.aws_iam_policy_document.trust.json
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "read_only" {
  role       = aws_iam_role.plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "state_lock" {
  statement {
    sid       = "StateBucketList"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.state_bucket}"]
  }

  statement {
    # Read-only on state. PR plans run with -lock=false (see terraform.yml), so this
    # PR-assumable (any-ref) role needs only GetObject to read state during plan — no
    # PutObject/DeleteObject, so it cannot write, delete, or corrupt state. Apply (the
    # only writer) runs locally with admin creds, never through this role.
    sid    = "ReadState"
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = [for k in local.planned_state_keys : "arn:aws:s3:::${local.state_bucket}/${k}/*"]
  }
}

resource "aws_iam_role_policy" "state_lock" {
  name   = "terraform-state-lock"
  role   = aws_iam_role.plan.id
  policy = data.aws_iam_policy_document.state_lock.json
}

output "plan_role_arn" {
  description = "Set as the AWS_PLAN_ROLE_ARN repo variable for the workflow."
  value       = aws_iam_role.plan.arn
}

# --- site deploy role (main branch only) ---

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "deploy_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${local.github_repo}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "deploy" {
  name                 = "github-actions-themiscpage-com-deploy"
  description          = "Site sync + invalidation for GitHub Actions in ${local.github_repo} (OIDC, main only)"
  assume_role_policy   = data.aws_iam_policy_document.deploy_trust.json
  max_session_duration = 3600
}

data "aws_iam_policy_document" "deploy" {
  statement {
    sid       = "SiteBucketList"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.site_bucket}"]
  }

  statement {
    sid    = "SiteBucketWrite"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["arn:aws:s3:::${local.site_bucket}/*"]
  }

  statement {
    # Invalidation only — cannot read or change distribution config. The distro
    # id lives in the main root's state, so scope by account rather than id.
    sid       = "Invalidate"
    effect    = "Allow"
    actions   = ["cloudfront:CreateInvalidation"]
    resources = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/*"]
  }
}

resource "aws_iam_role_policy" "deploy" {
  name   = "site-deploy"
  role   = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.deploy.json
}

output "deploy_role_arn" {
  description = "Set as the AWS_DEPLOY_ROLE_ARN repo variable for the deploy workflow."
  value       = aws_iam_role.deploy.arn
}
