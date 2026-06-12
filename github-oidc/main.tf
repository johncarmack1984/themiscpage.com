# CI for this repo: a plan-only role for GitHub Actions in
# johncarmack1984/themiscpage-infra. It reuses the OIDC provider created by the
# public my-infra/github-oidc root (one provider per account), referenced here
# as a data source.
#
# The role uses the AWS-managed ReadOnlyAccess policy for the plan refresh plus
# narrow read/write on just this repo's Terraform state + lock objects. It
# cannot apply.

locals {
  github_repo  = "johncarmack1984/themiscpage-infra"
  state_bucket = "john-carmack-terraform-state"

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
    sid    = "StateAndLockObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
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
