module "topology" {
    source = "../../topology"
    origin = "https://github.com/bkeane/stage.git"
    accounts = {
        "prod" = "677771948337"
        "dev" = "831926600600"
    }

    stages = [
        "s3"
    ]

    ecr_repositories = [
        "stage"
    ]
}

module "stage" {
    source = "../../stage"
    topology = module.topology
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

resource "local_file" "stages" {
  content = module.topology.stage_action
  filename = "../../.github/actions/stages/action.yaml"
}

resource "local_file" "build" {
  content = module.topology.ecr_action
  filename = "../../.github/actions/build/action.yaml"
}

output "topology" {
    value = module.topology
}