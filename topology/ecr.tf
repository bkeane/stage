locals {
    repository_names = sort([for url in data.corefunc_url_parse.repo: trim(url.path, "/")])
}

data "corefunc_url_parse" "repo" {
    count = length(var.ecr_repositories)
    url = "https://${var.ecr_repositories[count.index].repository_url}"
}

// Allow cross-account ECR read access to all stage accounts.
resource "aws_ecr_repository_policy" "cross_account_access" {
  count = length(local.repository_names)
  repository = local.repository_names[count.index]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Sid    = "CrossAccountPermission"
        Effect = "Allow"
        Principal = {
          AWS = concat([
            for id in local.account_ids :
            "arn:aws:iam::${id}:root"
          ])
        }
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
      },
      {
        Sid    = "LambdaECRImageRetrievalPolicy"
        Effect = "Allow"
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Condition = {
          StringLike = {
            "aws:sourceARN" : concat([
              for id in local.account_ids :
              "arn:aws:lambda:*:${id}:function:*"
            ])
          }
        }
      }
    ], var.extra_ecr_policy_statements)
  })
}
