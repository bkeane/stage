// Create ECR repositories.
resource "aws_ecr_repository" "repository" {
    for_each = var.repositories
    name = each.value
}

// Allow cross-account ECR read access to all stage accounts.
resource "aws_ecr_repository_policy" "cross_account_access" {
    for_each = aws_ecr_repository.repository
    repository = each.value.name
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Sid = "CrossAccountPermission"
                Effect = "Allow"
                Principal = {
                    AWS = concat([
                        for id in local.account_ids:
                            "arn:aws:iam::${id}:root"
                    ])
                }
                Action = [
                    "ecr:BatchGetImage",
                    "ecr:GetDownloadUrlForLayer"
                ]
            },
            {
                Sid = "LambdaECRImageRetrievalPolicy"
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
                        "aws:sourceARN": concat([
                            for id in local.account_ids:
                                "arn:aws:lambda:*:${id}:function:*"
                        ])
                    }
                }
            }
        ]
    })
}