locals {
    account_id = data.aws_caller_identity.current.account_id
    account_name = var.topology.account_lookup[local.account_id]
    account_region = data.aws_region.current.name

    resources = var.topology.resources[local.account_name][var.stage]
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_openid_connect_provider" "github" {
  arn = "arn:aws:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"
}