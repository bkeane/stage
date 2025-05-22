module "stage" {
    source = "../../stage"
    topology = data.terraform_remote_state.prod.outputs.topology
    stage = "s3"
    policy_document = data.aws_iam_policy_document.s3
}

data "aws_iam_policy_document" "s3" {
    statement {
        sid = "AllowS3Access"
        effect = "Allow"
        actions = [
            "s3:*"
        ]
        resources = [
            "arn:aws:s3:::kaixo-buildx-cache",
            "arn:aws:s3:::kaixo-buildx-cache/*"
        ]
    }
}

