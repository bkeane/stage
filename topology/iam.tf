locals {
  ecr_mgmt = local.resources[local.account_lookup[local.account_id]][var.ecr_stage_name]
}

#
# Push Role
#

resource "aws_iam_role" "ecr_mgmt" {
  name                  = local.ecr_mgmt.role_name
  description           = ""
  assume_role_policy    = data.aws_iam_policy_document.trust.json
  force_detach_policies = true
}

data "aws_iam_policy_document" "trust" {
  statement {
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        local.oidc.subject_claim
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecr_mgmt" {
  role       = aws_iam_role.ecr_mgmt.name
  policy_arn = aws_iam_policy.ecr_mgmt.arn
}

resource "aws_iam_policy" "ecr_mgmt" {
  name        = local.ecr_mgmt.policy_name
  description = ""
  policy      = data.aws_iam_policy_document.ecr_mgmt.json
}

data "aws_iam_policy_document" "ecr_mgmt" {
  statement {
    sid    = "AllowEcrRegistryRead"
    effect = "Allow"
    actions = [
      "ecr:List*",
      "ecr:Describe*",
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowEcrRepositoryWrite"
    effect = "Allow"

    actions = [
      "ecr:*",
    ]

    resources = flatten([
        for repo in var.repositories: 
        [
          "arn:aws:ecr:*:${local.account_id}:repository/${repo}",
          "arn:aws:ecr:*:${local.account_id}:repository/${repo}/*"
        ]
    ])
  }
}