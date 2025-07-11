locals {
    repository_names = sort([for url in data.corefunc_url_parse.repo: trim(url.path, "/")])
}

data "corefunc_url_parse" "repo" {
    count = length(var.ecr_repositories)
    url = "https://${var.ecr_repositories[count.index].repository_url}"
}

// Allow cross-account ECR read access to all stage accounts.
data "aws_iam_policy_document" "base_ecr_policy" {
  statement {
    sid    = "CrossAccountPermission"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        for id in local.account_ids :
        "arn:aws:iam::${id}:root"
      ]
    }
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
  }

  statement {
    sid    = "LambdaECRImageRetrievalPolicy"
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "aws:sourceARN"
      values = [
        for id in local.account_ids :
        "arn:aws:lambda:*:${id}:function:*"
      ]
    }
  }
}

// Merge the base policy with the additional policy documents if given.
data "aws_iam_policy_document" "merged_ecr_policy" {
  count = length(local.repository_names)
  
  source_policy_documents = concat(
    [data.aws_iam_policy_document.base_ecr_policy.json],
    [for doc in var.ecr_policy_documents : doc.json]
  )
}

// Apply the merged policy to the ECR repositories.
resource "aws_ecr_repository_policy" "cross_account_access" {
  count = length(local.repository_names)
  repository = local.repository_names[count.index]
  policy = data.aws_iam_policy_document.merged_ecr_policy[count.index].json
}
