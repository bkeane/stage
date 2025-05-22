#
# Stage Role
#

resource "aws_iam_role" "stage" {
  name                  = local.resources.role_name
  description           = ""
  assume_role_policy    = data.aws_iam_policy_document.trust.json
  force_detach_policies = true
  permissions_boundary = var.permissions_boundary.minified_json == "" ? null : aws_iam_policy.permissions_boundary[0].arn
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
        var.topology.oidc.subject_claim
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "stage" {
  role       = aws_iam_role.stage.name
  policy_arn = aws_iam_policy.policy.arn
}

#
# Policy
#

resource "aws_iam_policy" "policy" {
  name        = local.resources.policy_name
  description = ""
  policy      = var.policy_document.minified_json
}

#
# Boundary Policy
#

resource "aws_iam_policy" "permissions_boundary" {
  count       = var.permissions_boundary.minified_json == "" ? 0 : 1
  name        = local.resources.permissions_boundary_name
  description = ""
  policy      = var.permissions_boundary.minified_json
}