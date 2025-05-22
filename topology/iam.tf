#
# Push Role
#

resource "aws_iam_role" "ecr_stage" {
  name                  = local.ecr_stage.role_name
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

resource "aws_iam_role_policy_attachment" "ecr_stage" {
  role       = aws_iam_role.ecr_stage.name
  policy_arn = aws_iam_policy.ecr_stage.arn
}

resource "aws_iam_policy" "ecr_stage" {
  name        = local.ecr_stage.policy_name
  description = ""
  policy      = data.aws_iam_policy_document.ecr_stage.json
}

data "aws_iam_policy_document" "ecr_stage" {
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
    resources = [
        for repo in var.repositories: "arn:aws:ecr:*:${local.account_id}:repository/${repo}"
    ]
  }
}